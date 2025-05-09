WITH engaged_sessions AS (
  -- one row per engaged session (user_pseudo_id + ga_session_id) in Dec‑2020
  SELECT DISTINCT
    user_pseudo_id,
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'ga_session_id') AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE EXISTS (                          -- keep only engaged sessions
    SELECT 1
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'session_engaged'
      AND (ep.value.string_value = '1' OR ep.value.int_value = 1)
  )
), sessions_per_user AS (
  -- number of engaged sessions per user
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT ga_session_id) AS engaged_sessions
  FROM engaged_sessions
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id
)
-- average engaged sessions per user
SELECT
  ROUND(AVG(engaged_sessions), 4) AS avg_engaged_sessions_per_user
FROM sessions_per_user;