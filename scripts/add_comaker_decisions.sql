-- Run in Supabase SQL Editor (once) so co-maker approve/reject is tracked on loan_requests.
alter table public.loan_requests
  add column if not exists comaker_decisions jsonb not null default '{}'::jsonb;

comment on column public.loan_requests.comaker_decisions is
  'Map of co-maker shareholder_id -> status: pending | approved | rejected';

-- After adding the column, run scripts/backfill_comaker_decisions.sql once for existing rows.
