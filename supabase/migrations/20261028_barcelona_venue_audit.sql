-- Barcelona venue audit. No cards are published by this migration.
-- Current venue activity is corroborated, but all cards remain draft while visual rights are unresolved.
UPDATE public.venue_sources
SET verification_status='en attente de droits',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : activité actuelle corroborée par le programme du Love & Hope International Film Festival, qui annonce un événement LGBTQ+ au Boys Bar BCN le 15/10/2026 (Carrer de la Diputació, 174). Le site officiel est enregistré ; carte maintenue en brouillon, aucun droit d’image n’est présumé.')
WHERE card_id='3ff88ca3-3733-4eae-bd61-78d9e629d88a';

UPDATE public.venue_sources
SET verification_status='en attente de droits',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : le site officiel Safari Disco Club publie des événements à venir et des soirées LGBTQ+ récurrentes (YASS!, POPair, Bananas). Activité actuelle corroborée ; conserver en brouillon jusqu’à validation des visuels et de leurs droits.')
WHERE card_id='4fcd75c5-684d-484a-a191-acadfa80d4fa';

UPDATE public.venue_sources
SET verification_status='en attente de droits',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : le site officiel de Sauna Bruc présente toujours l’établissement et ses installations. Activité corroborée par la source officielle ; carte maintenue en brouillon, visuel et droits à valider avant publication.')
WHERE card_id='313a3a4a-fd46-4821-a6d0-2ba09b536533';

UPDATE public.venue_sources
SET last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : l’office de tourisme This is Barcelona présente La Federica comme bar culturel queer actif, au Carrer de Salvà, 3, avec programmation culturelle et horaires actuels. Photo issue de Barcelona Metropolitan toujours en prévisualisation uniquement ; droits non confirmés.')
WHERE card_id='a7f1e88f-ecc2-493a-9b6d-8859f401cbc4';
