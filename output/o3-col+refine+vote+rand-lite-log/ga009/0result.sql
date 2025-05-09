WITH engaged_sessions AS (
  -- One row per engaged session (user_pseudo_id + ga_session_id)
  SELECT DISTINCT
    user_pseudo_id,
    ( SELECT p.value.int_value
      FROM UNNEST(event_params) AS p
      WHERE p.key = 'ga_session_id'
    ) AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE EXISTS (
    SELECT 1
    FROM UNNEST(event_params) AS p
    WHERE p.key = 'session_engaged'
      AND (p.value.string_value = '1' OR p.value.int_value = 1)
  )
),
sessions_per_user AS (
  -- Count engaged sessions per user
  SELECT
    user_pseudo_id,
    COUNT(*) AS engaged_sessions
  FROM engaged_sessions
  GROUP BY user_pseudo_id
)
-- Average engaged sessions per user (rounded to 4 decimal places)
SELECT
  ROUND(AVG(engaged_sessions), 4) AS avg_engaged_sessions_per_user
FROM sessions_per_user;