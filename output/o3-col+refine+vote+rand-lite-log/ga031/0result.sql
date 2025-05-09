-- Home-to-Checkout-Confirmation session conversion rate for 02-Jan-2021
WITH base AS (   -- pick useful fields from 02-Jan-2021 page_view hits
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'ga_session_id')                AS ga_session_id,
    LOWER(                                          
      (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'page_title')                ) AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
    AND event_date = '20210102'
),
sessions AS (      -- one row per user-session, mark if it had Home / Checkout pages
  SELECT
    CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))               AS session_key,
    MAX(CASE WHEN page_title LIKE '%google online store%' OR page_title = 'home' 
             THEN 1 ELSE 0 END) AS has_home,
    MAX(CASE WHEN page_title LIKE '%checkout confirmation%' 
             THEN 1 ELSE 0 END) AS has_checkout
  FROM base
  GROUP BY session_key
),
totals AS (        -- count sessions
  SELECT
    COUNTIF(has_home = 1)                                AS home_sessions,
    COUNTIF(has_home = 1 AND has_checkout = 1)           AS converted_sessions
  FROM sessions
)
SELECT
  home_sessions,
  converted_sessions,
  SAFE_MULTIPLY(
      SAFE_DIVIDE(converted_sessions, home_sessions), 100
  ) AS session_conversion_rate_pct
FROM totals;