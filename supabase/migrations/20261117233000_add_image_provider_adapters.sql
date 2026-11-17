create or replace function public.admin_store_image_provider_key(p_provider text,p_api_key text)
returns boolean language plpgsql security definer set search_path=public,vault,auth as $$
declare v_name text;v_id uuid;v_role text;
begin
  select role::text into v_role from public.profiles where id=auth.uid();
  if v_role<>'admin' then raise exception 'Accès réservé à l’administration.' using errcode='42501'; end if;
  if p_provider not in ('openai','stability','google','replicate','fal','huggingface','bfl','ideogram','together') then raise exception 'Fournisseur non pris en charge.' using errcode='22023'; end if;
  if length(trim(coalesce(p_api_key,'')))<12 or length(p_api_key)>500 then raise exception 'Clé API invalide.' using errcode='22023'; end if;
  v_name:='gaycha_image_provider_'||p_provider;
  select id into v_id from vault.secrets where name=v_name limit 1;
  if v_id is null then perform vault.create_secret(trim(p_api_key),v_name,'Clé API images Gaycha Club · '||p_provider);
  else perform vault.update_secret(v_id,trim(p_api_key),v_name,'Clé API images Gaycha Club · '||p_provider); end if;
  return true;
end; $$;
revoke all on function public.admin_store_image_provider_key(text,text) from public,anon;
grant execute on function public.admin_store_image_provider_key(text,text) to authenticated;

create or replace function public.admin_image_provider_status()
returns jsonb language plpgsql security definer set search_path=public,vault,auth as $$
declare v_role text;
begin
  select role::text into v_role from public.profiles where id=auth.uid();
  if v_role<>'admin' then raise exception 'Accès réservé à l’administration.' using errcode='42501'; end if;
  return jsonb_build_object(
    'openai',exists(select 1 from vault.secrets where name='gaycha_image_provider_openai'),
    'stability',exists(select 1 from vault.secrets where name='gaycha_image_provider_stability'),
    'google',exists(select 1 from vault.secrets where name='gaycha_image_provider_google'),
    'replicate',exists(select 1 from vault.secrets where name='gaycha_image_provider_replicate'),
    'fal',exists(select 1 from vault.secrets where name='gaycha_image_provider_fal'),
    'huggingface',exists(select 1 from vault.secrets where name='gaycha_image_provider_huggingface'),
    'bfl',exists(select 1 from vault.secrets where name='gaycha_image_provider_bfl'),
    'ideogram',exists(select 1 from vault.secrets where name='gaycha_image_provider_ideogram'),
    'together',exists(select 1 from vault.secrets where name='gaycha_image_provider_together')
  );
end; $$;
revoke all on function public.admin_image_provider_status() from public,anon;
grant execute on function public.admin_image_provider_status() to authenticated;

create or replace function public.get_image_provider_key(p_provider text)
returns text language plpgsql security definer set search_path=public,vault,auth as $$
declare v_key text;
begin
  if auth.role()<>'service_role' then raise exception 'Accès réservé au service.' using errcode='42501'; end if;
  if p_provider not in ('openai','stability','google','replicate','fal','huggingface','bfl','ideogram','together') then raise exception 'Fournisseur non pris en charge.' using errcode='22023'; end if;
  select decrypted_secret into v_key from vault.decrypted_secrets where name='gaycha_image_provider_'||p_provider limit 1;
  return v_key;
end; $$;
revoke all on function public.get_image_provider_key(text) from public,anon,authenticated;
grant execute on function public.get_image_provider_key(text) to service_role;
