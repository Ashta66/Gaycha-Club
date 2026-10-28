-- Anonymous sessions may read only what RLS and SELECT grants expose.
-- All app mutations require authentication; signup/profile creation uses the auth trigger.
revoke insert, update, delete, truncate, references, trigger
on all tables in schema public
from anon;
