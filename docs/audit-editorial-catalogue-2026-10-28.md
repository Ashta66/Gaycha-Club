# Audit éditorial du catalogue Gaycha Club — 28 octobre 2026

## Périmètre et méthode
Audit ciblé sur les fiches de lieux LGBTQ+ et sur les données de catalogue accessibles dans Supabase. Les vérifications web sont des instantanés : elles ne remplacent pas la confirmation directe d’un établissement. Aucune carte n’a été publiée automatiquement.

## État global mesuré dans Supabase
- **112 fiches de lieux réels** reliées à `venue_sources`.
- **112/112 sans image intégrée** (`cards.image_path` vide).
- **86/112 sans source d’image renseignée**.
- **55 fiches** ont une source marquée « vérifié » alors que la carte reste en brouillon : statut de source et statut éditorial de carte sont deux notions distinctes.
- **29 fiches** ont une source marquée « vérifié » sans URL officielle renseignée.
- Statuts des cartes observés : 103 brouillons réels, 9 cartes réelles archivées, 12 cartes fictives publiées.
- Une recherche de doublons sur le nom exact normalisé en minuscules n’a pas retourné de doublon, mais cela ne détecte pas toutes les variantes d’écriture ni les alias.

## Décisions pour les fiches à risque
### Le Coxx — Montpellier
- Adresse rapportée par les sources : 5 rue Jules Latreilhe.
- Sources consultées contradictoires sur l’activité actuelle : lien officiel/social et répertoire Pride d’un côté, signalement de fermeture par un autre annuaire de l’autre.
- **Décision : rester en brouillon et « à vérifier »** jusqu’à confirmation directe. Aucun droit photo n’est présumé.

### Le Bar Queer — Montpellier
- Une source secondaire suggère une possible confusion avec « Le Mercury », à la même adresse (26 rue des Écoles Laïques).
- **Décision : ne pas fusionner ni publier** sans confirmation du nom commercial et de l’activité. Fiche conservée en brouillon et « à vérifier ».

### Le Moom Club — Montpellier
- Présent dans des annuaires, mais pas de confirmation officielle récente suffisamment probante trouvée dans l’audit.
- **Décision : rester en brouillon et « à vérifier »** ; ne pas le présenter comme actif sans confirmation directe.

### Le Heaven — fiche associée à Montpellier
- Les résultats trouvés autour de HEAVEN renvoient surtout à une soirée/organisation LGBTQ+ à Paris, notamment au Gibus, et ne valident pas cette fiche de discothèque montpelliéraine.
- **Décision : rester en brouillon et « à vérifier »** ; vérifier l’identité, la ville et le type de lieu avant toute publication.

### The Muse — Valence (Espagne)
- Le site officiel `https://themusevalencia.com/` et sa page d’événements `https://themusevalencia.com/eventos-valencia/` présentent le bar à C/ de Ruaya, 48 et annoncent des événements.
- Une source secondaire a toutefois signalé une possible fermeture ; le site officiel constitue un indice d’activité, pas une garantie d’ouverture quotidienne.
- **Décision : conserver en brouillon** jusqu’au contrôle final de l’adresse et de l’activité. Aucun droit de réutilisation d’image n’est établi.

## Règles de publication à maintenir
1. Une source indiquant qu’un lieu existe ne suffit pas à confirmer qu’il est actuellement actif.
2. Ne pas marquer les droits photo comme vérifiés simplement parce qu’une image figure sur le site officiel ou un réseau social.
3. Avant publication : vérifier le nom commercial, la ville, le type de lieu, l’activité récente, une source fiable, et la licence ou l’autorisation explicite de chaque visuel.
4. Garder les fiches incertaines en brouillon. Ne pas supprimer ou fusionner des fiches sur la seule base d’une ressemblance de nom ou d’adresse.
5. Le libellé « France & Espagne » n’est pas nécessaire dans les titres de séries/cartes/boosters ; conserver le pays dans les champs de localisation.

## Prochaines actions éditoriales
- Vérifier les 112 fiches individuellement, en commençant par les 29 marquées « vérifié » sans URL officielle et les 86 sans source d’image.
- Vérifier les doublons potentiels par alias, adresse, site officiel et variantes accentuées.
- Renseigner une source de description distincte de la source de l’image.
- N’intégrer les photos qu’après obtention d’une autorisation ou identification d’une licence compatible.
- Ne publier aucune fiche réelle automatiquement : la validation finale doit rester manuelle.

## Changements de données effectués
Les notes éditoriales ont été ajoutées aux quatre fiches montpelliéraines « Le Coxx », « Le Bar Queer », « Le Moom Club » et « Le Heaven », avec leur statut de vérification maintenu à « à vérifier ». Les cartes restent en brouillon. Aucune carte n’a été publiée, supprimée ou fusionnée.
