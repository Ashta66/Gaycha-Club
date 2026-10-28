create or replace function public.admin_set_booster(p_slug text, p_odds jsonb, p_price bigint, p_pity integer, p_cooldown integer, p_active boolean)
returns void language plpgsql security definer set search_path = ''
as $function$
declare u uuid:=auth.uid(); old public.booster_types; total numeric:=0; k text;
begin
  if u is null or not public.is_staff(array['admin']::public.app_role[]) then raise exception 'forbidden'; end if;
  if p_odds is null or jsonb_typeof(p_odds)<>'object' then raise exception 'odds must be a JSON object'; end if;
  if (select count(*) from jsonb_object_keys(p_odds))<>6 then raise exception 'odds must contain exactly the six rarity keys'; end if;
  select * into old from public.booster_types where slug=p_slug;
  if old.id is null then raise exception 'unknown booster'; end if;
  foreach k in array array['commun','peu_commun','rare','epique','legendaire','secrete'] loop
    if not (p_odds ? k) or jsonb_typeof(p_odds->k)<>'number' then raise exception 'missing or non-numeric odds for %',k; end if;
    if (p_odds->>k)::numeric<0 then raise exception 'negative odds for %',k; end if;
    total:=total+(p_odds->>k)::numeric;
  end loop;
  if abs(total-100)>0.001 then raise exception 'odds must sum to 100 (got %)',total; end if;
  if p_price is null or p_price<0 or p_pity is null or p_pity<1 or p_cooldown is null or p_cooldown<0 or p_active is null then raise exception 'invalid booster settings'; end if;
  update public.booster_types set odds=p_odds,price=p_price,pity_threshold=p_pity,cooldown_hours=p_cooldown,active=p_active where slug=p_slug;
  perform public.log_audit('booster.update',jsonb_build_object('slug',p_slug,'old',to_jsonb(old),'new',jsonb_build_object('odds',p_odds,'price',p_price,'pity',p_pity,'cooldown',p_cooldown,'active',p_active)));
end
$function$;
revoke all on function public.admin_set_booster(text,jsonb,bigint,integer,integer,boolean) from public, anon;
grant execute on function public.admin_set_booster(text,jsonb,bigint,integer,integer,boolean) to authenticated;
