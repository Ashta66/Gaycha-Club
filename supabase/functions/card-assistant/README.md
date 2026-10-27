# Assistant IA de cartes

La fonction Edge `card-assistant` est déployée sur le projet Supabase Gaycha Club. Elle vérifie la session et le rôle `admin` ou `catalog_manager`, puis utilise l'API OpenAI pour produire un brouillon JSON. Elle ne publie jamais directement une carte.

## Activation requise

Une clé OpenAI n'est pas incluse dans le dépôt. Pour activer la génération :

1. Ouvrir le projet Supabase `tgnembausaanuazoelxw`.
2. Aller dans **Edge Functions → Secrets** (ou **Project Settings → Edge Functions → Secrets**, selon l'interface).
3. Ajouter le secret `OPENAI_API_KEY` avec une clé API OpenAI valide.
4. Relancer l'assistant depuis le panneau Admin → Assistant IA.

Ne jamais mettre cette clé dans `index.html`, dans GitHub ou dans une variable accessible au navigateur.

La génération utilise `gpt-4o-mini` via l'API OpenAI et peut entraîner des frais API selon le compte OpenAI configuré. Les cartes générées restent en brouillon : le gestionnaire doit les relire et cliquer sur **Enregistrer**. Les cartes concernant des personnes réelles nécessitent une vérification humaine des droits avant publication.
