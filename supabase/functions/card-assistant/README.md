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


## Fonctions ajoutées

- Génération en lot de 10 propositions distinctes, sélectionnables une par une dans le formulaire de carte.
- Ton créatif ajustable (automatique selon la série, satire, absurde, pop/glamour, rétro ou fantasy).
- Génération séparée d'illustrations avec `gpt-image-1`, puis stockage dans le bucket public `card-art`. Les images sont générées à la demande, une par carte, afin d'éviter de lancer dix générations d'images coûteuses automatiquement.
- Historique des versions : la table `public.card_versions` conserve un instantané avant chaque modification/suppression de carte. La restauration recharge les champs dans le formulaire en brouillon, sans publier automatiquement.
- Workflow de relecture : les statuts `brouillon`, `revision` et `publie` sont gérés dans le panneau Admin. La publication reste une action manuelle confirmée.

La génération d'images nécessite que le compte API OpenAI autorise `gpt-image-1` et peut coûter davantage qu'une génération de texte. Les fichiers du bucket `card-art` sont publics pour que les illustrations des cartes s'affichent dans le jeu ; seuls les membres du staff autorisés peuvent y téléverser des fichiers via les règles Storage.
