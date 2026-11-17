create or replace function public.admin_delete_image_provider_key(p_provider text)
returns boolean language plpgsql security definer set search_path = '' as $$
declare v_role text; v_name text;
begin
 if auth.uid() is null then raise exception 'Authentification requise.' using errcode='42501'; end if;
 select role::text into v_role from public.profiles where id=auth.uid();
 if v_role is distinct from 'admin' then raise exception 'Accès réservé à l’administration.' using errcode='42501'; end if;
 if p_provider not in ('openai','stability','google','replicate','fal','huggingface','bfl','ideogram','together') then raise exception 'Fournisseur non pris en charge.' using errcode='22023'; end if;
 v_name := 'gaycha_image_provider_' || p_provider;
 delete from vault.secrets where name=v_name;
 perform public.log_audit('image_provider.delete',jsonb_build_object('provider',p_provider));
 return true;
end; $$;
revoke all on function public.admin_delete_image_provider_key(text) from public,anon;
grant execute on function public.admin_delete_image_provider_key(text) to authenticated;

create or replace function public.admin_audit_entries(p_limit integer default 100)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_rows jsonb;
begin
 if auth.uid() is null or not public.is_staff(array['admin']::public.app_role[]) then raise exception 'Accès réservé à l’administration.' using errcode='42501'; end if;
 select coalesce(jsonb_agg(to_jsonb(q) order by q.created_at desc,q.id desc),'[]'::jsonb) into v_rows
 from (
  select a.id,a.actor,a.action,a.details,a.created_at,actor.username as actor_username,beneficiary.username as beneficiary_username,booster.name as booster_name
  from public.audit_log a
  left join public.profiles actor on actor.id=a.actor
  left join public.profiles beneficiary on beneficiary.id=case when coalesce(a.details->>'user','') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then (a.details->>'user')::uuid else null end
  left join public.booster_types booster on booster.slug=a.details->>'slug'
  order by a.created_at desc,a.id desc limit greatest(1,least(coalesce(p_limit,100),200))
 ) q;
 return v_rows;
end; $$;
revoke all on function public.admin_audit_entries(integer) from public,anon;
grant execute on function public.admin_audit_entries(integer) to authenticated;
