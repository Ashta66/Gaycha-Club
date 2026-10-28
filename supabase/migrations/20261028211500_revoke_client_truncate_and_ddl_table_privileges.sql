-- RLS does not protect against TRUNCATE. Remove table-level capabilities
-- that normal clients should never need, across the exposed public schema.
revoke truncate, references, trigger on all tables in schema public from anon, authenticated;
