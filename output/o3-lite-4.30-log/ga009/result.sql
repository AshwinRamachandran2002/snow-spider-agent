WITH events_dec_2020 AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'ga_session_id'
     LIMIT 1) AS ga_session_id,
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'session_engaged'
     LIMIT 1) AS session_engaged
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
),
engaged_sessions AS (
  SELECT DISTINCT
    user_pseudo_id,
    ga_session_id
  FROM events_dec_2020
  WHERE session_engaged = 1
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))),
      COUNT(DISTINCT user_pseudo_id)
    ), 4
  ) AS average_engaged_sessions_per_user
FROM engaged_sessions;