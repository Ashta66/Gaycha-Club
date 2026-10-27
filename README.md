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

Trois séries sont préparées dans Supabase :
- **Bars gays & LGBTQ+ de France** — inclut également les lieux LGBTQ+ de Barcelone.
- **Discothèques gays & LGBTQ+** — inclut également les clubs LGBTQ+ de Barcelone.
- **Saunas gays** — inclut également les établissements de Barcelone.

Les premières fiches sont enregistrées en brouillon. Elles sont volontairement non publiées tant que l'équipe n'a pas vérifié l'activité de l'établissement, la description et les droits de l'image.

La table `venue_sources` associe une carte à son type de lieu, sa ville, son pays, son site officiel, la source de description, l'origine du visuel, son statut de vérification et sa licence. Les fiches de lieu affichent les liens de source et le statut des droits dans le détail de la carte.

### Règles éditoriales pour les établissements réels

1. Ne répertorier que des lieux explicitement gays ou LGBTQ+ (bars, clubs/discothèques et saunas), pas de simples lieux généralistes « friendly » sans preuve.
2. Préférer le site officiel ou les comptes officiels de l'établissement pour les descriptions, coordonnées et photos.
3. Ne publier une photo que si son utilisation est autorisée ou couverte par une licence claire. Une photo visible sur le Web n'est pas automatiquement libre de droits.
4. Conserver une URL source et une date de vérification, puis revérifier périodiquement les établissements et leurs informations pratiques.
5. Garder les cartes de lieux en brouillon jusqu'à validation éditoriale et vérification des droits.

## Données et sécurité

Les changements de base de données de la chasse aux secrets et du catalogue de lieux sont appliqués au projet Supabase. Avant de recréer le projet, exporter et versionner ces changements dans une migration SQL dédiée.
