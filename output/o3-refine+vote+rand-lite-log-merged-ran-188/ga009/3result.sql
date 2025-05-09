WITH engaged_sessions AS (
  -- keep only events where session_engaged = '1' (string or int)
  SELECT DISTINCT
    user_pseudo_id,
    (SELECT p.value.int_value
       FROM UNNEST(event_params) AS p
      WHERE p.key = 'ga_session_id'
      LIMIT 1) AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
       UNNEST(event_params) AS ep
  WHERE ep.key = 'session_engaged'
    AND (ep.value.string_value = '1' OR ep.value.int_value = 1)
),
sessions_per_user AS (
  SELECT
    user_pseudo_id,
    COUNT(*) AS engaged_session_count
  FROM engaged_sessions
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id
)
SELECT
  ROUND(AVG(engaged_session_count), 4) AS avg_engaged_sessions_per_user
FROM sessions_per_user;