do $$
declare
  p record;
  stmt text;
begin
  for p in
    select tablename, policyname, qual, with_check
    from pg_policies
    where schemaname = 'public'
      and (coalesce(qual, '') like '%auth.uid()%'
        or coalesce(with_check, '') like '%auth.uid()%')
      and policyname in (
        'blocks_own',
        'inst_read_own',
        'conv_read',
        'ledger_read_own',
        'listings_own',
        'msg_read',
        'claims_read_own',
        'profiles_read_own',
        'profiles_update_self'
      )
  loop
    stmt := format('alter policy %I on public.%I', p.policyname, p.tablename);
    if p.qual is not null then
      stmt := stmt || format(' using (%s)', replace(p.qual, 'auth.uid()', '(select auth.uid())'));
    end if;
    if p.with_check is not null then
      stmt := stmt || format(' with check (%s)', replace(p.with_check, 'auth.uid()', '(select auth.uid())'));
    end if;
    execute stmt;
  end loop;
end
$$;