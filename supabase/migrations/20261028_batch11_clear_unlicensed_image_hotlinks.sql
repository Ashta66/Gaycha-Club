-- Batch 11: remove external venue image URLs until reuse rights are confirmed.
-- Preserve the image source URLs and rights notes in venue_sources for follow-up.
update public.cards
set image_path = null
where id in (
  'd6768ef9-485f-42ec-a69e-86150140e006', -- Backstage · Perpignan
  '3807312c-a8e6-4cec-9657-1e6d923d63f4', -- Le Raidd Bar · Paris
  'a7f1e88f-ecc2-493a-9b6d-8859f401cbc4', -- La Federica · Barcelone
  'b32a605a-508f-4be6-b5fe-51ee39eaa7e9', -- Jet Set · Perpignan
  '3ee49323-7603-4978-819d-de08dd4ebbd0'  -- ONE Sauna · Montpellier
)
and rights_checked = false;
