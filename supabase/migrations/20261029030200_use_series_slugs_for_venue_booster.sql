-- Use immutable series slugs for venue booster selection, not display names.
-- Display names are intentionally editable and must not affect game mechanics.
CREATE OR REPLACE FUNCTION public.open_booster(
  p_booster text,
  p_key text,
  p_use_inventory boolean DEFAULT false,
  p_use_paid boolean DEFAULT false
)
RETURNS SETOF public.card_instances
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
declare
  u uuid := auth.uid();
  b public.booster_types;
  pr public.profiles;
  r public.rarity;
  c uuid;
  n int;
  x numeric;
  acc numeric;
  k text;
  pity boolean;
  inventory_qty integer := 0;
begin
  if u is null then raise exception 'auth required'; end if;
  if coalesce(p_use_inventory,false) and coalesce(p_use_paid,false) then
    raise exception 'invalid inventory source';
  end if;

  select * into pr from public.profiles where id=u for update;
  if pr.id is null or pr.is_suspended or pr.age_confirmed_at is null then
    raise exception 'forbidden';
  end if;
  if p_key is null or length(btrim(p_key))<8 then raise exception 'invalid request key'; end if;
  if exists(select 1 from public.ledger where idempotency_key=p_key) then
    raise exception 'duplicate request';
  end if;

  select * into b from public.booster_types where slug=p_booster and active;
  if b.id is null then raise exception 'unknown booster'; end if;

  if coalesce(p_use_inventory,false) or coalesce(p_use_paid,false) then
    if p_use_inventory then
      select quantity into inventory_qty
      from public.booster_inventory
      where user_id=u and booster_type_id=b.id for update;
      if coalesce(inventory_qty,0)<1 then raise exception 'no gifted booster available'; end if;
      update public.booster_inventory set quantity=quantity-1,updated_at=now()
      where user_id=u and booster_type_id=b.id;
      insert into public.ledger(user_id,delta,reason,ref,balance_after,idempotency_key)
      values(u,0,'booster_gift:'||b.slug,b.id,pr.balance,p_key);
    else
      select paid_quantity into inventory_qty
      from public.booster_inventory
      where user_id=u and booster_type_id=b.id for update;
      if coalesce(inventory_qty,0)<1 then raise exception 'no purchased booster available'; end if;
      update public.booster_inventory set paid_quantity=paid_quantity-1,updated_at=now()
      where user_id=u and booster_type_id=b.id;
      insert into public.ledger(user_id,delta,reason,ref,balance_after,idempotency_key)
      values(u,0,'booster_paid:'||b.slug,b.id,pr.balance,p_key);
    end if;
    delete from public.booster_inventory
    where user_id=u and booster_type_id=b.id and quantity<=0 and paid_quantity<=0;
  else
    if b.cooldown_hours>0 and exists(
      select 1 from public.ledger
      where user_id=u
        and reason in ('booster:'||b.slug,'booster_purchase:'||b.slug)
        and created_at>now()-make_interval(hours=>b.cooldown_hours)
    ) then raise exception 'cooldown active'; end if;
    if pr.balance<b.price then raise exception 'insufficient funds'; end if;
    insert into public.ledger(user_id,delta,reason,ref,balance_after,idempotency_key)
    values(u,-b.price,'booster:'||b.slug,b.id,pr.balance-b.price,p_key);
    update public.profiles set balance=balance-b.price where id=u;
  end if;

  for n in 1..b.cards_per_pack loop
    x:=(get_byte(extensions.gen_random_bytes(1),0)*65536
       +get_byte(extensions.gen_random_bytes(1),0)*256
       +get_byte(extensions.gen_random_bytes(1),0))/16777216.0*100;
    acc:=0;
    r:='commun';
    for k in select key from jsonb_object_keys(b.odds) as key
      order by array_position(array['commun','peu_commun','rare','epique','legendaire','secrete'],key)
    loop
      acc:=acc+(b.odds->>k)::numeric;
      if x<acc then r:=k::public.rarity; exit; end if;
    end loop;

    pity:=(select pity_counter from public.profiles where id=u)+1>=b.pity_threshold;
    if pity and r in ('commun','peu_commun') then r:='rare'; end if;
    update public.profiles
    set pity_counter=case when r in ('commun','peu_commun') then pity_counter+1 else 0 end
    where id=u;

    if p_booster='lieux-gays-lgbt' then
      select c1.id into c
      from public.cards c1
      join public.series s1 on s1.id=c1.series_id
      join public.venue_sources v1 on v1.card_id=c1.id
      where c1.rarity=r and c1.status='publie' and not c1.is_secret
        and v1.verification_status='vérifié'
        and s1.slug in ('bars-gays-france','discotheques-lgbtq','saunas-gays')
      order by random() limit 1;
    else
      select id into c from public.cards
      where rarity=r and status='publie' and not is_secret
      order by random() limit 1;
    end if;

    if c is null then raise exception 'no published card for rarity %',r; end if;
    return query
      with ins as (insert into public.card_instances(card_id,owner_id) values(c,u) returning *)
      select * from ins;
  end loop;
end
$function$;
