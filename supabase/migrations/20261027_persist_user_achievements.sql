create table if not exists public.user_achievements (
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_key text not null,
  unlocked_at timestamptz not null default now(),
  primary key (user_id, achievement_key),
  constraint user_achievements_key_check check (achievement_key in ('first_card','collector_10','rainbow_4','duplicates_5','completion'))
);
alter table public.user_achievements enable row level security;
revoke all on public.user_achievements from anon;
grant select on public.user_achievements to authenticated;
drop policy if exists "Users can read their own achievements" on public.user_achievements;
create policy "Users can read their own achievements" on public.user_achievements
  for select to authenticated using ((select auth.uid()) = user_id);

create or replace function public.sync_user_achievements()
returns table (achievement_key text, unlocked_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_unique integer;
  v_instances integer;
  v_rarities integer;
  v_catalogue integer;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  select count(distinct ci.card_id), count(*), count(distinct c.rarity::text)
    into v_unique, v_instances, v_rarities
  from public.card_instances ci
  join public.cards c on c.id = ci.card_id
  where ci.owner_id = v_user and c.status::text = 'publie';
  select count(*) into v_catalogue from public.cards c where c.status::text = 'publie';
  insert into public.user_achievements(user_id, achievement_key)
  select v_user, x.key
  from (values
    ('first_card', v_unique >= 1),
    ('collector_10', v_unique >= 10),
    ('rainbow_4', v_rarities >= 4),
    ('duplicates_5', v_instances - v_unique >= 5),
    ('completion', v_catalogue > 0 and v_unique >= v_catalogue)
  ) as x(key, achieved)
  where x.achieved
  on conflict (user_id, achievement_key) do nothing;
  return query select ua.achievement_key, ua.unlocked_at
    from public.user_achievements ua where ua.user_id = v_user order by ua.unlocked_at;
end;
$$;
revoke all on function public.sync_user_achievements() from public, anon;
grant execute on function public.sync_user_achievements() to authenticated;