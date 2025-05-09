-- session‑level conversion rate (Home  ➜  Checkout Confirmation)  
-- for 2 Jan 2021 using only `page_view` events
WITH page_views AS (
  SELECT
    user_pseudo_id,
    -- GA4 session identifier stored in the event parameter `ga_session_id`
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id')                         AS session_id,
    -- full page URL
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location')                         AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX = '20210102'          -- 2‑Jan‑2021
    AND event_name   = 'page_view'
),

session_flags AS (
  SELECT
    user_pseudo_id,
    session_id,
    -- did this session hit the Home page?
    MAX(
      CASE
        WHEN page_location IN ('https://shop.googlemerchandisestore.com/',
                               'https://googlemerchandisestore.com/')
        THEN 1 ELSE 0
      END
    ) AS has_home,
    -- did this session hit a Checkout Confirmation page?
    MAX(
      CASE
        WHEN REGEXP_CONTAINS(page_location,
                             r'/checkout.*(confirm|thank)')
        THEN 1 ELSE 0
      END
    ) AS has_confirmation
  FROM page_views
  GROUP BY user_pseudo_id, session_id
),

aggregated AS (
  SELECT
    COUNTIF(has_home = 1)                                   AS sessions_with_home,
    COUNTIF(has_home = 1 AND has_confirmation = 1)          AS sessions_with_home_and_confirmation
  FROM session_flags
)

SELECT
  ROUND(
    100 * sessions_with_home_and_confirmation
        / sessions_with_home , 4) AS conversion_rate_percent
FROM aggregated;