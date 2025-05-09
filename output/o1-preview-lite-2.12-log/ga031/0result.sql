WITH events AS (
  SELECT
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title') AS page_title
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE
    event_name = 'page_view'
    AND EXISTS (SELECT 1 FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id')
    AND EXISTS (SELECT 1 FROM UNNEST(event_params) ep WHERE ep.key = 'page_title')
),
sessions_with_home AS (
  SELECT DISTINCT ga_session_id
  FROM events
  WHERE page_title = 'Home'
),
sessions_with_checkout AS (
  SELECT DISTINCT ga_session_id
  FROM events
  WHERE page_title = 'Checkout Confirmation'
),
sessions_joined AS (
  SELECT
    s.ga_session_id,
    CASE WHEN c.ga_session_id IS NOT NULL THEN 1 ELSE 0 END AS has_checkout
  FROM sessions_with_home s
  LEFT JOIN sessions_with_checkout c
  ON s.ga_session_id = c.ga_session_id
),
totals AS (
  SELECT
    COUNT(*) AS total_sessions,
    SUM(has_checkout) AS sessions_with_checkout
  FROM sessions_joined
)
SELECT
  ROUND(SAFE_DIVIDE(sessions_with_checkout, total_sessions), 4) AS User_Session_Conversion_Rate
FROM totals;