create or replace function public.admin_get_account_detail(p_user uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_profile jsonb;v_avatar text;v_cards jsonb;v_history jsonb;v_boosters jsonb;v_total integer;
begin
 if auth.uid() is null or not public.is_staff(array['admin']::public.app_role[]) then raise exception 'forbidden' using errcode='42501';end if;
 if p_user is null then raise exception 'user required' using errcode='22023';end if;
 select jsonb_build_object('username',p.username,'role',p.role::text,'balance',p.balance,'xp',p.xp,'created_at',p.created_at,'is_suspended',p.is_suspended,'age_confirmed',p.age_confirmed_at is not null),coalesce(u.raw_user_meta_data->>'avatar_url',u.raw_user_meta_data->>'picture')
 into v_profile,v_avatar from public.profiles p join auth.users u on u.id=p.id where p.id=p_user;
 if v_profile is null then raise exception 'unknown user' using errcode='P0002';end if;
 v_profile:=v_profile||jsonb_build_object('avatar_url',v_avatar);
 select count(*)::integer into v_total from public.card_instances where owner_id=p_user;
 select coalesce(jsonb_agg(x.item order by x.acquired_at desc),'[]'::jsonb) into v_cards from (
   select jsonb_build_object('id',c.id,'name',c.name,'rarity',c.rarity::text,'image_path',c.image_path,'series_name',s.name,'quantity',q.quantity) as item,max(q.acquired_at) as acquired_at
   from (select card_id,count(*)::integer as quantity,max(acquired_at) as acquired_at from public.card_instances where owner_id=p_user group by card_id order by max(acquired_at) desc limit 12) q
   join public.cards c on c.id=q.card_id left join public.series s on s.id=c.series_id group by c.id,c.name,c.rarity,c.image_path,s.name,q.quantity,q.acquired_at
 ) x;
 select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb) into v_history from (
   select delta,reason,balance_after,created_at from public.ledger where user_id=p_user order by created_at desc limit 8
 ) x;
 select coalesce(jsonb_agg(jsonb_build_object('name',bt.name,'quantity',bi.quantity,'paid_quantity',bi.paid_quantity) order by bt.price,bt.name),'[]'::jsonb) into v_boosters
 from public.booster_inventory bi join public.booster_types bt on bt.id=bi.booster_type_id where bi.user_id=p_user and (bi.quantity>0 or bi.paid_quantity>0);
 return jsonb_build_object('profile',v_profile,'cards_total',v_total,'cards',coalesce(v_cards,'[]'::jsonb),'history',coalesce(v_history,'[]'::jsonb),'boosters',coalesce(v_boosters,'[]'::jsonb));
end;$$;
revoke all on function public.admin_get_account_detail(uuid) from public,anon;
grant execute on function public.admin_get_account_detail(uuid) to authenticated;
