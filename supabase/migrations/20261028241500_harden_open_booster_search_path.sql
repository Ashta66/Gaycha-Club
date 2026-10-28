-- Rebuild the existing booster RPC with a hardened search path and schema-qualified crypto.
do $migration$
declare
  definition text;
begin
  definition := pg_get_functiondef('public.open_booster(text,text,boolean,boolean)'::regprocedure);
  definition := replace(definition, 'SET search_path TO ''public'', ''extensions''', 'SET search_path TO ''''');
  definition := replace(definition, 'gen_random_bytes(', 'extensions.gen_random_bytes(');
  execute definition;
end
$migration$;

revoke all on function public.open_booster(text, text, boolean, boolean) from public, anon;
grant execute on function public.open_booster(text, text, boolean, boolean) to authenticated;
