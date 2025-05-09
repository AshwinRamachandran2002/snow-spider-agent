WITH engaged_sessions AS (
  SELECT DISTINCT
    user_pseudo_id,
    COALESCE(
      (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id' AND ep.value.int_value IS NOT NULL
       LIMIT 1),
      (SELECT SAFE_CAST(ep.value.string_value AS INT64)
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id' AND ep.value.string_value IS NOT NULL
       LIMIT 1)
    ) AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND EXISTS (
      SELECT 1
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'session_engaged'
        AND (ep.value.int_value = 1 OR ep.value.string_value = '1')
    )
)
SELECT
  AVG(session_count) AS avg_engaged_sessions_per_user
FROM (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT ga_session_id) AS session_count
  FROM engaged_sessions
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id
);