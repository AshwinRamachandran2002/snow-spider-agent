WITH engaged_sessions AS (
  -- one row per *engaged* session (identified by user_pseudo_id + ga_session_id)
  SELECT DISTINCT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id') AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_date BETWEEN '20201201' AND '20201231'
    -- keep only events whose session carries session_engaged = '1'
    AND EXISTS (
      SELECT 1
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'session_engaged'
        AND (ep.value.string_value = '1' OR ep.value.int_value = 1)
    )
),
sessions_per_user AS (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT ga_session_id) AS engaged_session_count
  FROM engaged_sessions
  WHERE ga_session_id IS NOT NULL          -- safety guard
  GROUP BY user_pseudo_id
)
SELECT
  ROUND(AVG(engaged_session_count), 4) AS avg_engaged_sessions_per_user
FROM sessions_per_user;