-- Friendship response policy validates participants and status, but table-level
-- UPDATE would still let a recipient rewrite requester_id/recipient_id.
-- Restrict direct updates to the response status column only.
revoke update on table public.friendships from anon, authenticated;
grant update (status) on table public.friendships to authenticated;
