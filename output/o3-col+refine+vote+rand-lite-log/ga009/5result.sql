WITH dec_2020_events AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'session_engaged') AS session_engaged,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id')   AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
),
user_session_counts AS (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT ga_session_id) AS engaged_sessions
  FROM dec_2020_events
  WHERE session_engaged = '1'
    AND ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id
)
SELECT
  ROUND(AVG(engaged_sessions), 4) AS avg_engaged_sessions_per_user_dec_2020
FROM user_session_counts;