WITH engaged_sessions AS (
  -- identify every distinct engaged session in Dec-2020
  SELECT DISTINCT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) AS ep
       WHERE ep.key = 'ga_session_id') AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE (
        SELECT COALESCE(ep.value.string_value,
                        CAST(ep.value.int_value AS STRING))
        FROM UNNEST(event_params) AS ep
        WHERE ep.key = 'session_engaged'
       ) = '1'
),
sessions_per_user AS (
  -- count engaged sessions per user
  SELECT
    user_pseudo_id,
    COUNT(*) AS engaged_sessions
  FROM engaged_sessions
  GROUP BY user_pseudo_id
)
-- average number of engaged sessions per user
SELECT
  ROUND(AVG(engaged_sessions), 4) AS avg_engaged_sessions_per_user
FROM sessions_per_user;