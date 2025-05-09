-- User-session conversion rate on 2-Jan-2021 based on page_view events
WITH page_views AS (
  SELECT
    user_pseudo_id,
    -- extract GA session id from event_params
    (SELECT CAST(p.value.int_value AS INT64)
       FROM UNNEST(event_params) AS p
       WHERE p.key = 'ga_session_id')                     AS ga_session_id,
    LOWER(                 -- normalise for case-insensitive matching
      (SELECT q.value.string_value
         FROM UNNEST(event_params) AS q
         WHERE q.key = 'page_title')
    )                                                     AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

sessions AS (           -- flag pages reached per (user,session)
  SELECT
    user_pseudo_id,
    ga_session_id,
    MAX(IF(page_title LIKE '%online store%', 1, 0))                   AS saw_home,
    MAX(IF(page_title LIKE '%checkout%'      OR
            page_title LIKE '%confirmation%' OR
            page_title LIKE '%thank%'       , 1, 0))                  AS saw_checkout
  FROM page_views
  GROUP BY user_pseudo_id, ga_session_id
)

SELECT
  COUNTIF(saw_home = 1)                                    AS sessions_with_home,
  COUNTIF(saw_home = 1 AND saw_checkout = 1)               AS sessions_with_home_and_checkout,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(saw_home = 1 AND saw_checkout = 1),
      COUNTIF(saw_home = 1)
    ) * 100, 2
  )                                                        AS session_conversion_rate_percent
FROM sessions;