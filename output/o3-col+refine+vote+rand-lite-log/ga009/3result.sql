-- Average number of engaged sessions per user for December-2020
WITH engaged_sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
      LIMIT 1) AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX LIKE '202012%'               -- December 2020 tables
    AND EXISTS (                                   -- keep only engaged sessions
      SELECT 1
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'session_engaged'
        AND (ep.value.string_value = '1' OR ep.value.int_value = 1)
    )
),
per_user AS (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT ga_session_id) AS engaged_sessions
  FROM engaged_sessions
  GROUP BY user_pseudo_id
)
SELECT
  ROUND(AVG(engaged_sessions), 4) AS avg_engaged_sessions_per_user
FROM per_user;