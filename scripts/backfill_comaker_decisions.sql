-- Run in Supabase SQL Editor after add_comaker_decisions.sql.
-- Rebuilds comaker_decisions from loan_comakers: one key per co-maker, value preserved
-- when already present (pending | approved | rejected), otherwise "pending".
--
-- Expects loan_comakers to be a JSON array (jsonb). If your column is uuid[] / text[]
-- instead, convert first, e.g. wrap with to_jsonb(loan_comakers).

UPDATE public.loan_requests AS lr
SET comaker_decisions = COALESCE(
  (
    SELECT jsonb_object_agg(
      cm.cm_id,
      COALESCE(lr.comaker_decisions->cm.cm_id, '"pending"'::jsonb)
    )
    FROM jsonb_array_elements_text(
      CASE
        WHEN lr.loan_comakers IS NULL THEN '[]'::jsonb
        WHEN jsonb_typeof(lr.loan_comakers::jsonb) = 'array' THEN lr.loan_comakers::jsonb
        ELSE '[]'::jsonb
      END
    ) AS cm(cm_id)
  ),
  '{}'::jsonb
);
