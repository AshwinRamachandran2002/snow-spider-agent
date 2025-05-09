WITH page_views AS (
  -- Pull the pieces we need from every “page_view” event on 2-Jan-2021
  SELECT
    user_pseudo_id,
    (SELECT value.int_value
       FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
      LIMIT 1)                        AS ga_session_id,
    LOWER(
      (SELECT value.string_value
         FROM UNNEST(event_params)
        WHERE key = 'page_title'
        LIMIT 1)
    )                                 AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

home_sessions AS (
  -- Any session that hit the Home page
  SELECT DISTINCT
    CONCAT(user_pseudo_id, '_', CAST(ga_session_id AS STRING)) AS session_key
  FROM page_views
  WHERE page_title IN ('home','google online store')
),

checkout_sessions AS (
  -- Any session that hit the Checkout Confirmation page
  SELECT DISTINCT
    CONCAT(user_pseudo_id, '_', CAST(ga_session_id AS STRING)) AS session_key
  FROM page_views
  WHERE page_title = 'checkout confirmation'
),

stats AS (
  SELECT
    COUNT(*) AS home_sessions,
    COUNT(DISTINCT hs.session_key) AS converting_sessions
  FROM home_sessions hs
  LEFT JOIN checkout_sessions cs
    ON hs.session_key = cs.session_key
  WHERE cs.session_key IS NOT NULL   -- keeps only sessions that reached both pages
)

SELECT
  home_sessions,
  converting_sessions,
  ROUND(SAFE_DIVIDE(converting_sessions, home_sessions) * 100, 4) AS conversion_rate_pct
FROM stats;