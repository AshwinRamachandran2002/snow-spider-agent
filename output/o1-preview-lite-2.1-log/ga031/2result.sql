WITH sessions_home AS (
  SELECT DISTINCT
    CONCAT(`user_pseudo_id`, CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING)) AS session_key
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE
    EXISTS (
      SELECT 1
      FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'page_title' AND ep.value.string_value = 'Home'
    )
),
sessions_checkout AS (
  SELECT DISTINCT
    CONCAT(`user_pseudo_id`, CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING)) AS session_key
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE
    EXISTS (
      SELECT 1
      FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'page_title' AND ep.value.string_value = 'Checkout Confirmation'
    )
),
conversion_sessions AS (
  SELECT COUNT(*) AS conversion_sessions
  FROM sessions_home
  INNER JOIN sessions_checkout USING (session_key)
),
total_home_sessions AS (
  SELECT COUNT(*) AS total_home_sessions
  FROM sessions_home
)
SELECT
  ROUND((conversion_sessions.conversion_sessions / total_home_sessions.total_home_sessions) * 100, 4) AS conversion_rate
FROM
  conversion_sessions,
  total_home_sessions;