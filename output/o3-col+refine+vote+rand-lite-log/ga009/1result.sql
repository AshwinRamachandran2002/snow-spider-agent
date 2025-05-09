WITH engaged_sessions AS (
  -- One row per engaged (user , session) combination in Dec-2020
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id') AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE EXISTS (
        SELECT 1
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'session_engaged'
          AND (ep.value.string_value = '1' OR ep.value.int_value = 1)
      )
  GROUP BY user_pseudo_id, ga_session_id
),
sessions_per_user AS (
  -- Count engaged sessions per user
  SELECT
    user_pseudo_id,
    COUNT(*) AS engaged_sessions
  FROM engaged_sessions
  GROUP BY user_pseudo_id
)
-- Final average number of engaged sessions per user
SELECT
  AVG(engaged_sessions) AS avg_engaged_sessions_per_user
FROM sessions_per_user;