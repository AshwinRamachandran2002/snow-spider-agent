WITH engaged_sessions AS (
  -- 1. pull only the events whose parameter `session_engaged` = '1'
  SELECT
    user_pseudo_id,
    -- take the numeric ga_session_id tied to the event
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'ga_session_id') AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE (
        SELECT ep.value.string_value
        FROM UNNEST(event_params) AS ep
        WHERE ep.key = 'session_engaged'
       ) = '1'
),
sessions_per_user AS (
  -- 2. count distinct sessions per user
  SELECT
    user_pseudo_id,
    COUNT(
      DISTINCT CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))
    ) AS engaged_sessions
  FROM engaged_sessions
  GROUP BY user_pseudo_id
)
-- 3. average engaged-session count across users
SELECT
  AVG(engaged_sessions) AS average_engaged_sessions_per_user
FROM sessions_per_user;