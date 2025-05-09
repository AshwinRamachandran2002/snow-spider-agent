SELECT
  ROUND(AVG(engaged_sessions_per_user), 4) AS average_engaged_sessions_per_user
FROM (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT ga_session_id) AS engaged_sessions_per_user
  FROM (
    SELECT
      t.user_pseudo_id,
      (SELECT ep.value.int_value FROM UNNEST(t.event_params) AS ep WHERE ep.key = 'session_engaged') AS session_engaged,
      (SELECT ep.value.int_value FROM UNNEST(t.event_params) AS ep WHERE ep.key = 'ga_session_id') AS ga_session_id
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS t
    WHERE t.event_date BETWEEN '20201201' AND '20201231'
  ) AS events
  WHERE session_engaged = 1
  GROUP BY user_pseudo_id
)