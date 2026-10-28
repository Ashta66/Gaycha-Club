-- Improve integrity and lookup performance for trades and secret challenges.
-- Existing trade_items rows were checked before migration: no duplicate key groups
-- and no null offer_id/side values. A surrogate key supports nullable instance_id.
alter table public.trade_items
  add column if not exists id uuid default gen_random_uuid();

update public.trade_items set id = gen_random_uuid() where id is null;

alter table public.trade_items
  alter column id set default gen_random_uuid(),
  alter column id set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.trade_items'::regclass and contype = 'p'
  ) then
    alter table public.trade_items add constraint trade_items_pkey primary key (id);
  end if;
end $$;

create index if not exists secret_attempts_user_challenge_attempted_idx
  on public.secret_attempts (user_id, challenge_id, attempted_at desc);
create index if not exists secret_attempts_challenge_id_idx
  on public.secret_attempts (challenge_id);
create index if not exists secret_challenges_reward_card_id_idx
  on public.secret_challenges (reward_card_id);
create index if not exists secret_discoveries_challenge_id_idx
  on public.secret_discoveries (challenge_id);
create index if not exists secret_discoveries_reward_card_id_idx
  on public.secret_discoveries (reward_card_id);
