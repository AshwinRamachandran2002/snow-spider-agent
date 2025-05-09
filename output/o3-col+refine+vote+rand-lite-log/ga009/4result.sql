-- Average number of engaged sessions per user in December 2020
WITH all_rows AS (
  SELECT
    user_pseudo_id,
    -- pull ga_session_id (INT64) from event_params
    (SELECT MAX(p.value.int_value)
       FROM UNNEST(event_params) AS p
       WHERE p.key = 'ga_session_id')                 AS ga_session_id,
    -- pull session_engaged flag (STRING) from event_params
    (SELECT MAX(p.value.string_value)
       FROM UNNEST(event_params) AS p
       WHERE p.key = 'session_engaged')               AS session_engaged
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
),
engaged_sessions AS (
  -- keep only rows where the session is flagged as engaged
  SELECT DISTINCT
    user_pseudo_id,
    ga_session_id
  FROM all_rows
  WHERE session_engaged = '1'
    AND ga_session_id IS NOT NULL
),
per_user_counts AS (
  -- count engaged sessions per user
  SELECT
    user_pseudo_id,
    COUNT(*) AS engaged_sessions
  FROM engaged_sessions
  GROUP BY user_pseudo_id
)
-- final average across users
SELECT
  ROUND(AVG(engaged_sessions), 4) AS average_engaged_sessions_per_user
FROM per_user_counts;