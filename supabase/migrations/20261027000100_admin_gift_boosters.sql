-- Gaycha Club Phase 2: admin booster gifts.
-- Review and apply only after staging tests; this migration is intentionally not applied here.

create table if not exists public.gifted_boosters (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  booster_slug text not null,
  gifted_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  opened_at timestamptz
);

create index if not exists gifted_boosters_owner_opened_idx
  on public.gifted_boosters(owner_id, opened_at, created_at desc);

alter table public.gifted_boosters enable row level security;

drop policy if exists gifted_boosters_read_own on public.gifted_boosters;
create policy gifted_boosters_read_own on public.gifted_boosters
  for select to authenticated using (owner_id = auth.uid());

drop policy if exists gifted_boosters_read_admin on public.gifted_boosters;
create policy gifted_boosters_read_admin on public.gifted_boosters
  for select to authenticated using (public.is_staff(array['admin']::public.app_role[]));

create or replace function public.admin_gift_booster(
  p_username text,
  p_booster text,
  p_mode text,
  p_count integer default 1
) returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare
  actor uuid := auth.uid();
  target public.profiles;
  b public.booster_types;
  gift_id uuid;
  i integer;
  n integer;
  x numeric;
  acc numeric;
  k text;
  r public.rarity;
  c uuid;
  pity boolean;
  cards_added integer := 0;
  gifts_added integer := 0;
begin
  if actor is null or not public.is_staff(array['admin']::public.app_role[]) then
    raise exception 'forbidden';
  end if;
  if p_mode not in ('inventory','immediate') then raise exception 'invalid gift mode'; end if;
  if p_count is null or p_count < 1 or p_count > 10 then raise exception 'count must be 1..10'; end if;

  select * into target from public.profiles
    where lower(username)=lower(btrim(p_username)) for update;
  if target.id is null then raise exception 'unknown player'; end if;
  if target.is_suspended or target.age_confirmed_at is null then
    raise exception 'target player is suspended or has not confirmed age';
  end if;
  select * into b from public.booster_types where slug=p_booster;
  if b.id is null then raise exception 'unknown booster'; end if;

  if p_mode='inventory' then
    if not b.active then raise exception 'booster is inactive; choose an active booster'; end if;
    for i in 1..p_count loop
      insert into public.gifted_boosters(owner_id,booster_slug,gifted_by)
        values(target.id,b.slug,actor);
      gifts_added := gifts_added + 1;
    end loop;
    perform public.log_audit('booster.gift.inventory',
      jsonb_build_object('target_user_id',target.id,'username',target.username,
        'booster_slug',b.slug,'count',p_count));
    return jsonb_build_object('mode',p_mode,'count',gifts_added,'cards',0);
  end if;

  -- Free opening: preserve normal rarity odds and pity counter, but do not charge
  -- credits or enforce the normal purchase cooldown.
  for i in 1..p_count loop
    for n in 1..b.cards_per_pack loop
      x := (get_byte(gen_random_bytes(1),0)*65536
        + get_byte(gen_random_bytes(1),0)*256
        + get_byte(gen_random_bytes(1),0)) / 16777216.0 * 100;
      acc := 0;
      r := 'commun';
      for k in
        select key from jsonb_object_keys(b.odds) as key
        order by array_position(array['commun','peu_commun','rare','epique','legendaire','secrete'],key)
      loop
        acc := acc + (b.odds->>k)::numeric;
        if x < acc then r := k::public.rarity; exit; end if;
      end loop;
      select pity_counter + 1 >= b.pity_threshold into pity
        from public.profiles where id=target.id;
      if pity and r in ('commun','peu_commun') then r := 'rare'; end if;
      update public.profiles
        set pity_counter=case when r in ('commun','peu_commun') then pity_counter+1 else 0 end
        where id=target.id;
      select id into c from public.cards
        where rarity=r and status='publie' order by random() limit 1;
      if c is null then raise exception 'no published card for rarity %',r; end if;
      insert into public.card_instances(card_id,owner_id) values(c,target.id);
      cards_added := cards_added + 1;
    end loop;
  end loop;
  perform public.log_audit('booster.gift.immediate',
    jsonb_build_object('target_user_id',target.id,'username',target.username,
      'booster_slug',b.slug,'count',p_count,'cards_added',cards_added));
  return jsonb_build_object('mode',p_mode,'count',p_count,'cards',cards_added);
end
$function$;

create or replace function public.open_gifted_booster(p_gift_id uuid)
returns setof public.card_instances
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare
  actor uuid := auth.uid();
  gift public.gifted_boosters;
  b public.booster_types;
  pr public.profiles;
  r public.rarity;
  c uuid;
  n integer;
  x numeric;
  acc numeric;
  k text;
  pity boolean;
begin
  if actor is null then raise exception 'auth required'; end if;
  select * into pr from public.profiles where id=actor for update;
  if pr.id is null or pr.is_suspended or pr.age_confirmed_at is null then
    raise exception 'forbidden';
  end if;
  select * into gift from public.gifted_boosters
    where id=p_gift_id and owner_id=actor and opened_at is null for update;
  if gift.id is null then raise exception 'gift not found or already opened'; end if;
  select * into b from public.booster_types where slug=gift.booster_slug;
  if b.id is null then raise exception 'booster configuration missing'; end if;

  update public.gifted_boosters set opened_at=now() where id=gift.id;
  for n in 1..b.cards_per_pack loop
    x := (get_byte(gen_random_bytes(1),0)*65536
      + get_byte(gen_random_bytes(1),0)*256
      + get_byte(gen_random_bytes(1),0)) / 16777216.0 * 100;
    acc := 0;
    r := 'commun';
    for k in
      select key from jsonb_object_keys(b.odds) as key
      order by array_position(array['commun','peu_commun','rare','epique','legendaire','secrete'],key)
    loop
      acc := acc + (b.odds->>k)::numeric;
      if x < acc then r := k::public.rarity; exit; end if;
    end loop;
    select pity_counter + 1 >= b.pity_threshold into pity
      from public.profiles where id=actor;
    if pity and r in ('commun','peu_commun') then r := 'rare'; end if;
    update public.profiles
      set pity_counter=case when r in ('commun','peu_commun') then pity_counter+1 else 0 end
      where id=actor;
    select id into c from public.cards
      where rarity=r and status='publie' order by random() limit 1;
    if c is null then raise exception 'no published card for rarity %',r; end if;
    return query insert into public.card_instances(card_id,owner_id)
      values(c,actor) returning *;
  end loop;
  perform public.log_audit('booster.gift.open',
    jsonb_build_object('gift_id',gift.id,'booster_slug',b.slug,'cards_added',b.cards_per_pack));
end
$function$;

revoke all on function public.admin_gift_booster(text,text,text,integer) from public;
grant execute on function public.admin_gift_booster(text,text,text,integer) to authenticated;
revoke all on function public.open_gifted_booster(uuid) from public;
grant execute on function public.open_gifted_booster(uuid) to authenticated;
