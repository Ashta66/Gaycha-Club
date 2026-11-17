-- Harden Vault-backed image-provider administration against missing profiles.
-- Keep the RPCs available to authenticated callers, but require a real admin profile.
create or replace function public.admin_image_provider_status()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_role text;
begin
  if auth.uid() is null then
    raise exception 'Authentification requise.' using errcode='42501';
  end if;

  select role::text into v_role
  from public.profiles
  where id = auth.uid();

  if v_role is distinct from 'admin' then
    raise exception 'Accès réservé à l’administration.' using errcode='42501';
  end if;

  return jsonb_build_object(
    'openai', exists(select 1 from vault.secrets where name='gaycha_image_provider_openai'),
    'stability', exists(select 1 from vault.secrets where name='gaycha_image_provider_stability'),
    'google', exists(select 1 from vault.secrets where name='gaycha_image_provider_google'),
    'replicate', exists(select 1 from vault.secrets where name='gaycha_image_provider_replicate'),
    'fal', exists(select 1 from vault.secrets where name='gaycha_image_provider_fal'),
    'huggingface', exists(select 1 from vault.secrets where name='gaycha_image_provider_huggingface'),
    'bfl', exists(select 1 from vault.secrets where name='gaycha_image_provider_bfl'),
    'ideogram', exists(select 1 from vault.secrets where name='gaycha_image_provider_ideogram'),
    'together', exists(select 1 from vault.secrets where name='gaycha_image_provider_together')
  );
end;
$function$;

revoke all on function public.admin_image_provider_status() from public, anon;
grant execute on function public.admin_image_provider_status() to authenticated;

create or replace function public.admin_store_image_provider_key(p_provider text, p_api_key text)
returns boolean
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_name text;
  v_id uuid;
  v_role text;
begin
  if auth.uid() is null then
    raise exception 'Authentification requise.' using errcode='42501';
  end if;

  select role::text into v_role
  from public.profiles
  where id = auth.uid();

  if v_role is distinct from 'admin' then
    raise exception 'Accès réservé à l’administration.' using errcode='42501';
  end if;

  if p_provider is null or p_provider not in ('openai','stability','google','replicate','fal','huggingface','bfl','ideogram','together') then
    raise exception 'Fournisseur non pris en charge.' using errcode='22023';
  end if;

  if p_api_key is null or length(trim(p_api_key)) < 12 or length(p_api_key) > 500 then
    raise exception 'Clé API invalide.' using errcode='22023';
  end if;

  v_name := 'gaycha_image_provider_' || p_provider;
  select id into v_id from vault.secrets where name=v_name limit 1;

  if v_id is null then
    perform vault.create_secret(trim(p_api_key),v_name,'Clé API images Gaycha Club · '||p_provider);
  else
    perform vault.update_secret(v_id,trim(p_api_key),v_name,'Clé API images Gaycha Club · '||p_provider);
  end if;

  perform public.log_audit('image_provider.store',jsonb_build_object('provider',p_provider));
  return true;
end;
$function$;

revoke all on function public.admin_store_image_provider_key(text,text) from public, anon;
grant execute on function public.admin_store_image_provider_key(text,text) to authenticated;
