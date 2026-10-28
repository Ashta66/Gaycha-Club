import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.0";

const cors = {
  "Access-Control-Allow-Origin": "https://ashta66.github.io",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
  "Vary": "Origin",
};

const reply = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: cors });

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("Origin");
  if (origin && origin !== "https://ashta66.github.io") {
    return new Response(JSON.stringify({ error: "Origine non autorisée." }), {
      status: 403,
      headers: cors,
    });
  }
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply(405, { error: "Méthode non autorisée." });
  const declaredLength = Number(req.headers.get("content-length") || "0");
  if (Number.isFinite(declaredLength) && declaredLength > 16000) {
    return reply(413, { error: "Requête trop volumineuse." });
  }

  const openaiKey = Deno.env.get("OPENAI_API_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!openaiKey) return reply(503, { error: "Assistant IA non configuré : ajoutez le secret OPENAI_API_KEY dans Supabase Edge Functions." });
  if (!supabaseUrl || !anonKey) return reply(503, { error: "Configuration Supabase manquante." });

  const auth = req.headers.get("Authorization") || "";
  const token = auth.replace(/^Bearer\s+/i, "");
  if (!token) return reply(401, { error: "Connexion requise." });

  const supabase = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: { user }, error: authError } = await supabase.auth.getUser(token);
  if (authError || !user) return reply(401, { error: "Session invalide." });

  // Use the private self-profile RPC: direct SELECT of role is intentionally revoked.
  const { data: profile, error: profileError } = await supabase.rpc("get_my_profile");
  if (
    profileError ||
    profile?.is_suspended === true ||
    !["admin", "catalog_manager"].includes(profile?.role || "")
  ) {
    return reply(403, { error: "Accès réservé aux administrateurs et gestionnaires du catalogue actifs." });
  }

  let input: { action?: string; mode?: string; prompt?: string; existing?: Record<string, unknown>; seriesName?: string; style?: string; cardName?: string };
  try {
    const rawBody = await req.text();
    if (new TextEncoder().encode(rawBody).byteLength > 16000) {
      return reply(413, { error: "Requête trop volumineuse." });
    }
    input = JSON.parse(rawBody);
  } catch { return reply(400, { error: "Requête JSON invalide." }); }
  const prompt = String(input.prompt || "").trim();
  if (input.action === "illustration") {
    if (prompt.length < 8 || prompt.length > 1800) return reply(400, { error: "Décrivez l’illustration en 8 à 1800 caractères." });
    const { error: quotaError } = await supabase.rpc("consume_card_assistant_quota", { p_action: "illustration" });
    if (quotaError) {
      const limited = /rate limit/i.test(quotaError.message || "");
      return reply(limited ? 429 : 403, { error: limited ? "Quota de génération atteint. Réessayez plus tard." : "Accès à la génération refusé." });
    }
    const imageResponse = await fetch("https://api.openai.com/v1/images/generations", {
      method: "POST",
      headers: { "Authorization": "Bearer " + openaiKey, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "gpt-image-1", prompt: "Illustration originale pour une carte à collectionner Gaycha Club, public adulte. Visuel portrait stylisé, composition lisible en petit format. Aucun texte, signature ou logo. Concept: " + prompt.slice(0, 1500), size: "1024x1536", quality: "medium", n: 1 }),
    });
    if (!imageResponse.ok) { const detail = await imageResponse.text(); console.error("OpenAI image API error", imageResponse.status, detail.slice(0, 300)); return reply(502, { error: imageResponse.status === 401 ? "La clé OpenAI est invalide." : "La génération d’illustration a échoué. Vérifiez que votre compte API a accès à gpt-image-1." }); }
    const imageData = await imageResponse.json(); const image = imageData.data?.[0]?.b64_json;
    if (!image) return reply(502, { error: "L’API n’a pas retourné de fichier image exploitable." });
    return reply(200, { image, mimeType: "image/png" });
  }
  if (!["create", "edit"].includes(input.mode || "") || prompt.length < 8 || prompt.length > 1800) {
    return reply(400, { error: "Choisissez création/modification et décrivez la carte (8 à 1800 caractères)." });
  }
  if (input.mode === "edit" && !input.existing) return reply(400, { error: "Choisissez une carte à modifier." });
  const { error: quotaError } = await supabase.rpc("consume_card_assistant_quota", { p_action: "text" });
  if (quotaError) {
    const limited = /rate limit/i.test(quotaError.message || "");
    return reply(limited ? 429 : 403, { error: limited ? "Quota de génération atteint. Réessayez plus tard." : "Accès à la génération refusé." });
  }

  const system = `Tu es l’assistant éditorial de Gaycha Club, un jeu satirique de cartes à collectionner pour adultes. Tu proposes des brouillons amusants, bienveillants et originaux en français. Adapte le ton à la série et au style demandé: ${String(input.style || "auto").slice(0, 40)}. Pour un lot, produis des concepts distincts, sans répéter les mêmes blagues ou noms.
Ne prétends jamais qu’une citation est réelle. Ne crée pas de faits biographiques, accusations ou citations attribués à une personne réelle. Pour une personne réelle, propose une caricature clairement satirique et demande que les droits soient vérifiés avant publication. Réponds uniquement selon le schéma JSON imposé. La rareté doit être une des valeurs commun, peu_commun, rare, epique, legendaire, secrete. status doit toujours être brouillon. rights_checked doit toujours être false. is_fictional est true sauf si l’utilisateur demande explicitement une personne réelle.`
  const userPrompt = JSON.stringify({
    mode: input.mode,
    serie: String(input.seriesName || "").slice(0, 120),
    consigne: prompt,
    carte_existante: input.mode === "edit" ? input.existing : null,
    instruction: "Génère ou améliore un brouillon de carte. Conserve les champs pertinents en modification. Ne publie jamais la carte."
  });

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { "Authorization": `Bearer ${openaiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      temperature: 0.8,
      max_tokens: 900,
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "gaycha_card_draft",
          strict: true,
          schema: {
            type: "object",
            additionalProperties: false,
            properties: {
              number: { type: "integer" },
              name: { type: "string" },
              rarity: { type: "string", enum: ["commun", "peu_commun", "rare", "epique", "legendaire", "secrete"] },
              spec: { type: "string" },
              anecdote: { type: "string" },
              bio: { type: "string" },
              is_fictional: { type: "boolean" },
              rights_checked: { type: "boolean" },
              status: { type: "string", enum: ["brouillon"] }
            },
            required: ["number", "name", "rarity", "spec", "anecdote", "bio", "is_fictional", "rights_checked", "status"]
          }
        }
      },
      messages: [{ role: "system", content: system }, { role: "user", content: userPrompt }]
    }),
  });

  if (!response.ok) {
    const detail = await response.text();
    console.error("OpenAI API error", response.status, detail.slice(0, 500));
    return reply(502, { error: response.status === 401 ? "La clé OpenAI configurée est invalide." : "Le service IA n'a pas pu générer le brouillon. Réessayez." });
  }
  const data = await response.json();
  try {
    const draft = JSON.parse(data.choices?.[0]?.message?.content || "");
    draft.number = Math.max(1, Math.min(99999, Number(draft.number) || 1));
    draft.name = String(draft.name || "").trim().slice(0, 100);
    draft.spec = String(draft.spec || "").trim().slice(0, 180);
    draft.anecdote = String(draft.anecdote || "").trim().slice(0, 400);
    draft.bio = String(draft.bio || "").trim().slice(0, 1200);
    draft.status = "brouillon";
    draft.rights_checked = false;
    return reply(200, { draft });
  } catch {
    return reply(502, { error: "La réponse IA n'a pas pu être interprétée." });
  }
});