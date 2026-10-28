# Gaycha Club

Gaycha Club est un site de cartes à collectionner avec boosters, collection, échanges et univers narratif.

## Chasse aux secrets

- La page **Univers** affiche les énigmes disponibles pour les membres connectés.
- Les réponses sont vérifiées par la fonction PostgreSQL `attempt_secret_challenge`; les solutions ne sont pas stockées dans le JavaScript du navigateur.
- Les tentatives sont limitées à 8 par énigme et par heure.
- Une résolution enregistre la découverte et ajoute la carte secrète à la collection.
- Les cartes secrètes sont masquées par la politique RLS tant que le joueur ne les a pas débloquées.
- Les boosters excluent les cartes secrètes : elles se découvrent par énigme.

## Séries de lieux LGBTQ+

Les trois séries couvrent la France et l'Espagne. **État vérifié dans Supabase le 28 octobre 2026 : 112 fiches de lieux réels, dont 103 brouillons et 9 archivées ; aucune fiche de lieu n'est publiée.** Répartition actuelle : **55 bars**, **24 discothèques/clubs** et **33 saunas**. Le catalogue complet compte 124 cartes : 12 cartes publiées hors de ces séries de lieux. Les fiches de lieux ne doivent pas être publiées avant validation éditoriale et vérification manuelle des droits des visuels.

Perpignan est représentée dans les trois séries : Backstage (bar), UBA Club (lieu historique, signalé comme fermé depuis 2020 dans une source secondaire) et L'Équateur (sauna dont l'ouverture actuelle doit être confirmée). Les fiches peuvent désigner des lieux fermés ou non vérifiés ; elles ne doivent pas être publiées avant contrôle manuel.

Les fiches récentes n'ont pas de photo intégrée. Les droits des images, les descriptions, les adresses, les horaires et le statut actuel doivent être vérifiés avant publication. L'onglet d'administration **Lieux LGBTQ+** permet de compléter les sources, le visuel et les informations de vérification.

## Données et sécurité

Les changements de base de données de la chasse aux secrets et du catalogue de lieux sont appliqués au projet Supabase. Avant de recréer le projet, exporter et versionner ces changements dans une migration SQL dédiée.

### Intégrité et performance des données

- Ajout d'une clé primaire UUID à `trade_items` après contrôle des données existantes.
- Ajout d'index pour les tentatives, défis et découvertes secrets, ainsi que pour les clés étrangères de l'historique des versions de cartes.
- Les migrations ont été appliquées au projet Supabase connecté et sont versionnées dans `supabase/migrations/`.

### Renforcement du profil et expérience de collection

- Les lectures directes de `profiles` sont limitées aux champs communautaires (`id`, `username`, `bio`, `xp`, `created_at`). Les données privées (solde, rôle, confirmation d’âge et suspension) passent par `get_my_profile()`, qui ne renvoie que le profil de la session authentifiée.
- La progression de l’album affiche le taux global de cartes découvertes et la progression par série.
- La recherche d’amis montre la bio publique et l’XP, avec un raccourci vers les messages pour les amis déjà acceptés.
- Migration appliquée au projet Supabase : `20261028194650_harden_profile_column_visibility`.
