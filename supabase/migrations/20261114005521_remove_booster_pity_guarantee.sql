-- Remove booster pity guarantees while retaining RPC signatures for old clients.
-- The p_pity argument is ignored by the admin RPCs for backward compatibility.
-- Historical profile.pity_counter values are preserved but no longer affect draws.

CREATE OR REPLACE FUNCTION public.admin_set_booster(p_slug text, p_odds jsonb, p_price bigint, p_pity integer, p_cooldown integer, p_active boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  u uuid := auth.uid();
  old public.booster_types;
  total numeric := 0;
  k text;
BEGIN
  IF u IS NULL OR NOT public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_odds IS NULL OR jsonb_typeof(p_odds) <> 'object' THEN
    RAISE EXCEPTION 'odds must be a JSON object';
  END IF;
  IF (SELECT count(*) FROM jsonb_object_keys(p_odds)) <> 6 THEN
    RAISE EXCEPTION 'odds must contain exactly the six rarity keys';
  END IF;

  SELECT * INTO old FROM public.booster_types WHERE slug = p_slug FOR UPDATE;
  IF old.id IS NULL THEN RAISE EXCEPTION 'unknown booster'; END IF;

  FOREACH k IN ARRAY ARRAY['commun','peu_commun','rare','epique','legendaire','secrete'] LOOP
    IF NOT (p_odds ? k) OR jsonb_typeof(p_odds->k) <> 'number' THEN
      RAISE EXCEPTION 'missing or non-numeric odds for %', k;
    END IF;
    IF (p_odds->>k)::numeric < 0 THEN RAISE EXCEPTION 'negative odds for %', k; END IF;
    total := total + (p_odds->>k)::numeric;
  END LOOP;

  IF abs(total - 100) > 0.001 THEN RAISE EXCEPTION 'odds must sum to 100 (got %)', total; END IF;
  IF p_price IS NULL OR p_price < 0
     OR p_cooldown IS NULL OR p_cooldown < 0 OR p_active IS NULL THEN
    RAISE EXCEPTION 'invalid booster settings';
  END IF;

  -- p_pity is intentionally ignored; retained only for backward compatibility.
  UPDATE public.booster_types
     SET odds = p_odds, price = p_price,
         cooldown_hours = p_cooldown, active = p_active
   WHERE slug = p_slug;

  PERFORM public.log_audit(
    'booster.update',
    jsonb_build_object('slug', p_slug, 'old', to_jsonb(old),
      'new', jsonb_build_object('odds', p_odds, 'price', p_price,
                                'cooldown', p_cooldown, 'active', p_active))
  );
END
$function$
;

CREATE OR REPLACE FUNCTION public.admin_upsert_booster(p_slug text, p_name text, p_cards_per_pack integer, p_odds jsonb, p_price bigint, p_pity integer, p_cooldown integer, p_active boolean)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  old public.booster_types;
  total numeric := 0;
  k text;
  result_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_slug IS NULL OR p_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' OR char_length(p_slug) > 80 THEN
    RAISE EXCEPTION 'invalid booster slug';
  END IF;
  IF p_name IS NULL OR char_length(btrim(p_name)) < 2 OR char_length(btrim(p_name)) > 100 THEN
    RAISE EXCEPTION 'invalid booster name';
  END IF;
  IF p_cards_per_pack IS NULL OR p_cards_per_pack < 1 OR p_cards_per_pack > 50 THEN
    RAISE EXCEPTION 'cards per pack must be between 1 and 50';
  END IF;
  IF p_odds IS NULL OR jsonb_typeof(p_odds) <> 'object' OR (SELECT count(*) FROM jsonb_object_keys(p_odds)) <> 6 THEN
    RAISE EXCEPTION 'odds must contain exactly the six rarity keys';
  END IF;
  FOREACH k IN ARRAY ARRAY['commun','peu_commun','rare','epique','legendaire','secrete'] LOOP
    IF NOT (p_odds ? k) OR jsonb_typeof(p_odds->k) <> 'number' THEN
      RAISE EXCEPTION 'missing or non-numeric odds for %', k;
    END IF;
    IF (p_odds->>k)::numeric < 0 THEN RAISE EXCEPTION 'negative odds for %', k; END IF;
    total := total + (p_odds->>k)::numeric;
  END LOOP;
  IF abs(total - 100) > 0.001 THEN RAISE EXCEPTION 'odds must sum to 100 (got %)', total; END IF;
  IF p_price IS NULL OR p_price < 0 OR p_cooldown IS NULL OR p_cooldown < 0 OR p_active IS NULL THEN
    RAISE EXCEPTION 'invalid booster settings';
  END IF;

  SELECT * INTO old FROM public.booster_types WHERE slug = p_slug FOR UPDATE;
  IF old.id IS NULL THEN
    INSERT INTO public.booster_types(slug,name,cards_per_pack,odds,price,cooldown_hours,active)
    VALUES(p_slug,btrim(p_name),p_cards_per_pack,p_odds,p_price,p_cooldown,p_active)
    RETURNING id INTO result_id;
  ELSE
    UPDATE public.booster_types
       SET name=btrim(p_name), cards_per_pack=p_cards_per_pack, odds=p_odds, price=p_price,
           cooldown_hours=p_cooldown, active=p_active
     WHERE id=old.id RETURNING id INTO result_id;
  END IF;
  -- p_pity is intentionally ignored; retained only for backward compatibility.
  PERFORM public.log_audit(
    CASE WHEN old.id IS NULL THEN 'booster.create' ELSE 'booster.update' END,
    jsonb_build_object('slug',p_slug,'old',to_jsonb(old),'new',jsonb_build_object(
      'name',btrim(p_name),'cards_per_pack',p_cards_per_pack,'odds',p_odds,'price',p_price,
      'cooldown',p_cooldown,'active',p_active))
  );
  RETURN result_id;
END
$function$
;

CREATE OR REPLACE FUNCTION public.open_booster(p_booster text, p_key text, p_use_inventory boolean DEFAULT false, p_use_paid boolean DEFAULT false)
 RETURNS SETOF card_instances
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  u uuid := auth.uid();
  b public.booster_types;
  pr public.profiles;
  r public.rarity;
  c uuid;
  n int;
  x numeric;
  acc numeric;
  k text;
  inventory_qty integer := 0;
BEGIN
  IF u IS NULL THEN RAISE EXCEPTION 'auth required'; END IF;
  IF coalesce(p_use_inventory,false) AND coalesce(p_use_paid,false) THEN
    RAISE EXCEPTION 'invalid inventory source';
  END IF;

  SELECT * INTO pr FROM public.profiles WHERE id=u FOR UPDATE;
  IF pr.id IS NULL OR pr.is_suspended OR pr.age_confirmed_at IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_key IS NULL OR length(btrim(p_key))<8 THEN RAISE EXCEPTION 'invalid request key'; END IF;
  IF EXISTS(SELECT 1 FROM public.ledger WHERE idempotency_key=p_key) THEN
    RAISE EXCEPTION 'duplicate request';
  END IF;

  SELECT * INTO b FROM public.booster_types WHERE slug=p_booster AND active;
  IF b.id IS NULL THEN RAISE EXCEPTION 'unknown booster'; END IF;

  IF coalesce(p_use_inventory,false) OR coalesce(p_use_paid,false) THEN
    IF p_use_inventory THEN
      SELECT quantity INTO inventory_qty
      FROM public.booster_inventory
      WHERE user_id=u AND booster_type_id=b.id FOR UPDATE;
      IF coalesce(inventory_qty,0)<1 THEN RAISE EXCEPTION 'no gifted booster available'; END IF;
      UPDATE public.booster_inventory SET quantity=quantity-1,updated_at=now()
      WHERE user_id=u AND booster_type_id=b.id;
      INSERT INTO public.ledger(user_id,delta,reason,ref,balance_after,idempotency_key)
      VALUES(u,0,'booster_gift:'||b.slug,b.id,pr.balance,p_key);
    ELSE
      SELECT paid_quantity INTO inventory_qty
      FROM public.booster_inventory
      WHERE user_id=u AND booster_type_id=b.id FOR UPDATE;
      IF coalesce(inventory_qty,0)<1 THEN RAISE EXCEPTION 'no purchased booster available'; END IF;
      UPDATE public.booster_inventory SET paid_quantity=paid_quantity-1,updated_at=now()
      WHERE user_id=u AND booster_type_id=b.id;
      INSERT INTO public.ledger(user_id,delta,reason,ref,balance_after,idempotency_key)
      VALUES(u,0,'booster_paid:'||b.slug,b.id,pr.balance,p_key);
    END IF;
    DELETE FROM public.booster_inventory
    WHERE user_id=u AND booster_type_id=b.id AND quantity<=0 AND paid_quantity<=0;
  ELSE
    IF b.cooldown_hours>0 AND EXISTS(
      SELECT 1 FROM public.ledger
      WHERE user_id=u
        AND reason IN ('booster:'||b.slug,'booster_purchase:'||b.slug)
        AND created_at>now()-make_interval(hours=>b.cooldown_hours)
    ) THEN RAISE EXCEPTION 'cooldown active'; END IF;
    IF pr.balance<b.price THEN RAISE EXCEPTION 'insufficient funds'; END IF;
    INSERT INTO public.ledger(user_id,delta,reason,ref,balance_after,idempotency_key)
    VALUES(u,-b.price,'booster:'||b.slug,b.id,pr.balance-b.price,p_key);
    UPDATE public.profiles SET balance=balance-b.price WHERE id=u;
  END IF;

  FOR n IN 1..b.cards_per_pack LOOP
    x:=(get_byte(extensions.gen_random_bytes(1),0)*65536
       +get_byte(extensions.gen_random_bytes(1),0)*256
       +get_byte(extensions.gen_random_bytes(1),0))/16777216.0*100;
    acc:=0;
    r:='commun';
    FOR k IN SELECT key FROM jsonb_object_keys(b.odds) AS key
      ORDER BY array_position(ARRAY['commun','peu_commun','rare','epique','legendaire','secrete'],key)
    LOOP
      acc:=acc+(b.odds->>k)::numeric;
      IF x<acc THEN r:=k::public.rarity; EXIT; END IF;
    END LOOP;

    IF p_booster='lieux-gays-lgbt' THEN
      SELECT c1.id INTO c
      FROM public.cards c1
      JOIN public.series s1 ON s1.id=c1.series_id
      JOIN public.venue_sources v1 ON v1.card_id=c1.id
      WHERE c1.rarity=r AND c1.status='publie' AND NOT c1.is_secret
        AND v1.verification_status='vérifié'
        AND s1.slug IN ('bars-gays-france','discotheques-lgbtq','saunas-gays')
      ORDER BY random() LIMIT 1;
    ELSE
      SELECT id INTO c FROM public.cards
      WHERE rarity=r AND status='publie' AND NOT is_secret
      ORDER BY random() LIMIT 1;
    END IF;

    IF c IS NULL THEN RAISE EXCEPTION 'no published card for rarity %',r; END IF;
    RETURN QUERY
      WITH ins AS (INSERT INTO public.card_instances(card_id,owner_id) VALUES(c,u) RETURNING *)
      SELECT * FROM ins;
  END LOOP;
END
$function$
;
