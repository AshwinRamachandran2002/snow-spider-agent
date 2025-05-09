WITH dec_2020_events AS (
  SELECT
    user_pseudo_id,
    -- grab the session id once per event
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) AS ep
     WHERE ep.key = 'ga_session_id'
     LIMIT 1) AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  -- restrict to the December 2020 daily tables
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    -- keep only events whose session was marked as engaged
    AND EXISTS (
      SELECT 1
      FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'session_engaged'
        AND (ep.value.string_value = '1' OR ep.value.int_value = 1)
    )
),
user_session_counts AS (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT ga_session_id) AS engaged_sessions
  FROM dec_2020_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id
)
SELECT
  AVG(engaged_sessions) AS avg_engaged_sessions_per_user
FROM user_session_counts;