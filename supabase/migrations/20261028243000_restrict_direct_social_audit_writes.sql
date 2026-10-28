-- Defense in depth for data that must only be changed by validated RPCs.
revoke insert, update, delete, truncate, references, trigger
  on table public.audit_log,
           public.blocks,
           public.conversations,
           public.messages,
           public.reports,
           public.secret_discoveries,
           public.user_achievements
  from anon, authenticated;

-- Profile deletion is never a client action; profile creation is handled by the signup trigger.
revoke delete on table public.profiles from anon, authenticated;
