alter table public.booster_types add column if not exists presentation jsonb not null default '{}'::jsonb;
create or replace function public.admin_set_booster_presentation(p_slug text,p_presentation jsonb)
returns boolean language plpgsql security definer set search_path='' as $$
declare v_old jsonb;v_logo text;v_effect text;
begin
 if auth.uid() is null or not public.is_staff(array['admin','catalog_manager']::public.app_role[]) then raise exception 'forbidden' using errcode='42501';end if;
 if p_slug is null or p_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' then raise exception 'invalid booster slug' using errcode='22023';end if;
 if p_presentation is null or jsonb_typeof(p_presentation)<>'object' then raise exception 'invalid presentation' using errcode='22023';end if;
 if coalesce(p_presentation->>'primary','') !~ '^#[0-9A-Fa-f]{6}$' or coalesce(p_presentation->>'secondary','') !~ '^#[0-9A-Fa-f]{6}$' or coalesce(p_presentation->>'accent','') !~ '^#[0-9A-Fa-f]{6}$' then raise exception 'invalid presentation colors' using errcode='22023';end if;
 v_effect:=coalesce(p_presentation->>'effect','shine');if v_effect not in ('shine','glow','pride','sparkle','none') then raise exception 'invalid presentation effect' using errcode='22023';end if;
 v_logo:=nullif(btrim(p_presentation->>'logo_url'),'');if v_logo is not null and (length(v_logo)>500 or v_logo !~ '^https://') then raise exception 'logo URL must use HTTPS' using errcode='22023';end if;
 select presentation into v_old from public.booster_types where slug=p_slug for update;if not found then raise exception 'unknown booster';end if;
 update public.booster_types set presentation=jsonb_build_object('primary',p_presentation->>'primary','secondary',p_presentation->>'secondary','accent',p_presentation->>'accent','effect',v_effect,'logo_url',v_logo) where slug=p_slug;
 perform public.log_audit('booster.presentation.update',jsonb_build_object('slug',p_slug,'old',v_old,'new',p_presentation));
 return true;
end;$$;
revoke all on function public.admin_set_booster_presentation(text,jsonb) from public,anon;
grant execute on function public.admin_set_booster_presentation(text,jsonb) to authenticated;
