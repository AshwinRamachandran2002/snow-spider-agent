WITH engaged_events AS (
  -- keep only events from Dec‑2020 that have session_engaged = 1
  SELECT
    user_pseudo_id,
    ( SELECT ep.value.int_value
      FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'ga_session_id'
            AND ep.value.int_value IS NOT NULL
      LIMIT 1 ) AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND EXISTS (
      SELECT 1
      FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'session_engaged'
            AND (ep.value.string_value = '1' OR ep.value.int_value = 1)
    )
),
-- one row per engaged session
engaged_sessions AS (
  SELECT DISTINCT user_pseudo_id, ga_session_id
  FROM engaged_events
  WHERE ga_session_id IS NOT NULL
),
-- count engaged sessions per user
sessions_per_user AS (
  SELECT
    user_pseudo_id,
    COUNT(*) AS engaged_session_count
  FROM engaged_sessions
  GROUP BY user_pseudo_id
)
-- average engaged sessions per user
SELECT
  ROUND(AVG(engaged_session_count), 4) AS avg_engaged_sessions_per_user
FROM sessions_per_user;