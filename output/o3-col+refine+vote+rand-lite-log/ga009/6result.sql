WITH engaged_sessions AS (
  SELECT DISTINCT
         user_pseudo_id,
         (SELECT ep.value.int_value
          FROM   UNNEST(event_params) AS ep
          WHERE  ep.key = 'ga_session_id'
          LIMIT  1) AS ga_session_id
  FROM   `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE  _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND  EXISTS (
          SELECT 1
          FROM   UNNEST(event_params) AS p
          WHERE  p.key = 'session_engaged'
            AND  (p.value.string_value = '1' OR p.value.int_value = 1)
        )
),
sessions_per_user AS (
  SELECT
    user_pseudo_id,
    COUNT(*) AS engaged_sessions
  FROM engaged_sessions
  GROUP BY user_pseudo_id
)
SELECT
  ROUND(AVG(engaged_sessions), 4) AS avg_engaged_sessions_per_user
FROM sessions_per_user;