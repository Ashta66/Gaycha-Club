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


const IMAGE_PROVIDERS = ["openai","stability","google","replicate","fal","huggingface","bfl","ideogram","together"] as const;
type ImageProvider = typeof IMAGE_PROVIDERS[number];
const toBase64 = (bytes: Uint8Array) => { let binary=""; for(let i=0;i<bytes.length;i+=0x8000) binary+=String.fromCharCode(...bytes.subarray(i,i+0x8000)); return btoa(binary); };
const imageFromUrl = async (url:string) => { const r=await fetch(url); if(!r.ok) throw new Error("Téléchargement du visuel impossible ("+r.status+")."); const mime=r.headers.get("content-type")||"image/png"; if(!mime.startsWith("image/")) throw new Error("Le fournisseur n’a pas renvoyé une image."); return {image:toBase64(new Uint8Array(await r.arrayBuffer())),mimeType:mime.split(";")[0]}; };
const responseError = async (r:Response,provider:string) => { const raw=(await r.text()).slice(0,1200); console.error("Image provider error",provider,r.status,raw.replace(/(Bearer\s+)[^\s"]+/gi,"$1[redacted]")); let payload:any=null; try{payload=JSON.parse(raw)}catch{} const providerCode=String(payload?.error?.code||payload?.error?.type||""); const moderationReason=String(payload?.name||payload?.errors?.[0]||providerCode).toLowerCase(); if(provider==="OpenAI"&&(providerCode==="insufficient_quota"||providerCode==="credit_balance_exhausted"))return new Error("Le compte OpenAI n’a plus de crédits API. Ajoute des crédits dans la facturation OpenAI ou sélectionne un autre fournisseur configuré dans Gaycha Club."); if(r.status===403&&(moderationReason.includes("content_moderation")||moderationReason.includes("moderation")))return new Error("La demande a été bloquée par la modération de "+provider+". Essaie une description plus neutre, sans termes ambigus."); if(r.status===401)return new Error("Clé API "+provider+" invalide."); if(r.status===403)return new Error(provider+" refuse l’accès à cette clé ou à ce modèle."); if(r.status===402)return new Error("Crédits ou facturation insuffisants chez "+provider+"."); if(r.status===429)return new Error("Limite temporaire de requêtes atteinte chez "+provider+". Réessaie plus tard ou vérifie le quota de ce fournisseur."); return new Error(provider+" a refusé la génération (HTTP "+r.status+"). Vérifie le modèle, les crédits et les paramètres."); };
const generateProviderImages = async (provider:ImageProvider,key:string,prompt:string,count:number) => {
 const p="Portrait vertical 2:3 pour une carte à collectionner Gaycha Club, illustration originale, adulte, LGBTQ+, style éditorial premium et coloré. Aucun texte, aucune signature, aucun logo. "+prompt.slice(0,1450);
 const images:Array<{image:string,mimeType:string}>=[];
 if(provider==="openai"){
  const r=await fetch("https://api.openai.com/v1/images/generations",{method:"POST",headers:{Authorization:"Bearer "+key,"Content-Type":"application/json"},body:JSON.stringify({model:"gpt-image-1",prompt:p,size:"1024x1536",quality:"medium",n:count})}); if(!r.ok)throw await responseError(r,"OpenAI"); const d=await r.json(); for(const x of d.data||[])if(typeof x.b64_json==="string")images.push({image:x.b64_json,mimeType:"image/png"});
 }else if(provider==="stability"){
  for(let i=0;i<count;i++){const form=new FormData();form.set("prompt",p);form.set("aspect_ratio","2:3");form.set("output_format","png");const r=await fetch("https://api.stability.ai/v2beta/stable-image/generate/core",{method:"POST",headers:{Authorization:"Bearer "+key,Accept:"application/json"},body:form});if(!r.ok)throw await responseError(r,"Stability AI");const d=await r.json();if(typeof d.image==="string")images.push({image:d.image,mimeType:"image/png"});}
 }else if(provider==="google"){
  for(let i=0;i<count;i++){const r=await fetch("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key="+encodeURIComponent(key),{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({contents:[{parts:[{text:p}]}],generationConfig:{responseModalities:["IMAGE"]}})});if(!r.ok)throw await responseError(r,"Google Gemini");const d=await r.json();const part=d.candidates?.[0]?.content?.parts?.find((x:any)=>x.inlineData?.data);if(part)images.push({image:part.inlineData.data,mimeType:part.inlineData.mimeType||"image/png"});}
 }else if(provider==="replicate"){
  for(let i=0;i<count;i++){const r=await fetch("https://api.replicate.com/v1/models/black-forest-labs/flux-schnell/predictions",{method:"POST",headers:{Authorization:"Bearer "+key,"Content-Type":"application/json",Prefer:"wait=60"},body:JSON.stringify({input:{prompt:p,aspect_ratio:"2:3",output_format:"png"}})});if(!r.ok)throw await responseError(r,"Replicate");let d=await r.json();for(let n=0;n<20&&d.status!=="succeeded"&&d.status!=="failed"&&d.urls?.get;n++){await new Promise(resolve=>setTimeout(resolve,1500));const poll=await fetch(d.urls.get,{headers:{Authorization:"Bearer "+key}});if(!poll.ok)throw await responseError(poll,"Replicate");d=await poll.json();}if(d.status!=="succeeded")throw new Error(d.status==="failed"?"Replicate n’a pas pu produire le visuel.":"Replicate met trop de temps à répondre. Réessaie.");const out=Array.isArray(d.output)?d.output:[d.output];for(const url of out.filter((x:any)=>typeof x==="string").slice(0,1))images.push(await imageFromUrl(url));}
 }else if(provider==="fal"){
  const r=await fetch("https://fal.run/fal-ai/flux/schnell",{method:"POST",headers:{Authorization:"Key "+key,"Content-Type":"application/json"},body:JSON.stringify({prompt:p,image_size:"portrait_4_3",num_images:count,enable_safety_checker:true})});if(!r.ok)throw await responseError(r,"fal.ai");const d=await r.json();for(const x of (d.images||[]).slice(0,count))if(x.url)images.push(await imageFromUrl(x.url));
 }else if(provider==="huggingface"){
  for(let i=0;i<count;i++){const r=await fetch("https://router.huggingface.co/hf-inference/models/black-forest-labs/FLUX.1-schnell",{method:"POST",headers:{Authorization:"Bearer "+key,"Content-Type":"application/json",Accept:"image/png"},body:JSON.stringify({inputs:p,parameters:{width:768,height:1152}})});if(!r.ok)throw await responseError(r,"Hugging Face");const mime=r.headers.get("content-type")||"image/png";if(mime.includes("application/json"))throw new Error("Hugging Face n’a pas renvoyé d’image : modèle indisponible ou en chargement.");images.push({image:toBase64(new Uint8Array(await r.arrayBuffer())),mimeType:mime.split(";")[0]});}
 }else if(provider==="bfl"){
  for(let i=0;i<count;i++){const r=await fetch("https://api.bfl.ai/v1/flux-2-pro",{method:"POST",headers:{"x-key":key,"Content-Type":"application/json",Accept:"application/json"},body:JSON.stringify({prompt:p,width:768,height:1152,output_format:"png"})});if(!r.ok)throw await responseError(r,"Black Forest Labs");const task=await r.json();const pollUrl=task.polling_url||("https://api.bfl.ai/v1/get_result?id="+encodeURIComponent(task.id||""));let result:any=null;for(let n=0;n<25;n++){await new Promise(resolve=>setTimeout(resolve,1500));const poll=await fetch(pollUrl,{headers:{"x-key":key,Accept:"application/json"}});if(!poll.ok)throw await responseError(poll,"Black Forest Labs");result=await poll.json();if(result.status==="Ready"||result.status==="completed"||result.result?.sample)break;if(result.status==="Error"||result.status==="failed")throw new Error("FLUX n’a pas pu produire le visuel.");}const url=result?.result?.sample||result?.result?.url;if(!url)throw new Error("FLUX n’a pas renvoyé de lien d’image exploitable.");images.push(await imageFromUrl(url));}
 }else if(provider==="ideogram"){
  const r=await fetch("https://api.ideogram.ai/v2/image/generate/ideogram-4-5",{method:"POST",headers:{"Api-Key":key,"Content-Type":"application/json"},body:JSON.stringify({prompt:p,num_images:count,aspect_ratio:"2:3",rendering_speed:"BALANCED",magic_prompt:"AUTO"})});if(!r.ok)throw await responseError(r,"Ideogram");const d=await r.json();for(const x of (d.data||[]).slice(0,count))if(x.url)images.push(await imageFromUrl(x.url));
 }else if(provider==="together"){
  const r=await fetch("https://api.together.xyz/v1/images/generations",{method:"POST",headers:{Authorization:"Bearer "+key,"Content-Type":"application/json"},body:JSON.stringify({model:"black-forest-labs/FLUX.1-schnell",prompt:p,width:768,height:1152,n:count,response_format:"b64_json"})});if(!r.ok)throw await responseError(r,"Together AI");const d=await r.json();for(const x of d.data||[]){if(typeof x.b64_json==="string")images.push({image:x.b64_json,mimeType:"image/png"});else if(typeof x.url==="string")images.push(await imageFromUrl(x.url));}
 }
 return images.slice(0,count);
};
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

  let input: { action?: string; mode?: string; prompt?: string; existing?: Record<string, unknown>; seriesName?: string; style?: string; cardName?: string; count?: number; provider?: string };
  try {
    const rawBody = await req.text();
    if (new TextEncoder().encode(rawBody).byteLength > 16000) {
      return reply(413, { error: "Requête trop volumineuse." });
    }
    input = JSON.parse(rawBody);
  } catch { return reply(400, { error: "Requête JSON invalide." }); }
  const prompt = String(input.prompt || "").trim();
  if (input.action === "illustration") {
    if(prompt.length<8||prompt.length>1800)return reply(400,{error:"Décrivez l’illustration en 8 à 1800 caractères."});
    const provider=String(input.provider||"openai") as ImageProvider;
    if(!IMAGE_PROVIDERS.includes(provider))return reply(400,{error:"Fournisseur non pris en charge."});
    const serviceKey=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if(!serviceKey)return reply(503,{error:"Configuration sécurisée des clés indisponible dans Supabase."});
    const serviceClient=createClient(supabaseUrl,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});
    const {data:apiKey,error:keyError}=await serviceClient.rpc("get_image_provider_key",{p_provider:provider});
    if(keyError){console.error("Image key lookup failed",provider,keyError.message);return reply(503,{error:"Impossible de lire la clé "+provider+". Vérifie la configuration des fournisseurs dans l’administration."});}
    if(!apiKey)return reply(503,{error:"Aucune clé API "+provider+" configurée. Ouvre Assistant IA > Fournisseurs d’illustrations, choisis ce service et enregistre sa clé."});
    const {data:quotaRequestId,error:quotaError}=await supabase.rpc("reserve_card_assistant_quota",{p_action:"illustration"});
    if(quotaError){const limited=/rate limit/i.test(quotaError.message||"");return reply(limited?429:403,{error:limited?"Quota de génération atteint. Réessaie plus tard.":"Accès à la génération refusé."});}
    const count=Math.max(1,Math.min(4,Math.floor(Number(input.count)||1)));
    try{const images=await generateProviderImages(provider,String(apiKey),prompt,count);if(!images.length)throw new Error("Le fournisseur n’a retourné aucun visuel exploitable.");return reply(200,{images,image:images[0].image,mimeType:images[0].mimeType,provider});}
    catch(error){if(quotaRequestId!==null&&quotaRequestId!==undefined){const {error:releaseError}=await supabase.rpc("release_card_assistant_quota",{p_request_id:quotaRequestId});if(releaseError)console.error("Image quota refund failed",releaseError.message);}const message=error instanceof Error?error.message:"Erreur inconnue du fournisseur d’images.";console.error("Image generation failed",provider,message);return reply(502,{error:message});}
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