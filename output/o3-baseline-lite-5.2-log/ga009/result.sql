/* Average number of engaged sessions per user (December 2020) */
WITH engaged_sessions AS (
  -- Keep one row per (user, session) that contains session_engaged = 1
  SELECT DISTINCT
    user_pseudo_id,
    (
      SELECT ep.value.int_value          -- ga_session_id is stored in int_value
      FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'ga_session_id'
      LIMIT 1
    ) AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE EXISTS (
    SELECT 1
    FROM UNNEST(event_params) AS ep
    WHERE ep.key = 'session_engaged'
      AND (ep.value.string_value = '1' OR ep.value.int_value = 1)
  )
),
sessions_per_user AS (
  -- Count engaged sessions for every user
  SELECT
    user_pseudo_id,
    COUNT(*) AS engaged_session_count
  FROM engaged_sessions
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id
)
-- Compute the average across users
SELECT
  AVG(engaged_session_count) AS avg_engaged_sessions_per_user
FROM sessions_per_user;