WITH page_views AS (
  -- Pull only page_view events for 2 Jan 2021 and extract the fields we need
  SELECT
    user_pseudo_id,
    -- GA4 session identifier
    CAST((
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
    ) AS INT64)                                             AS session_id,
    
    -- Page URL and title (force lower‑case for easy matching)
    LOWER(
      COALESCE((
        SELECT ep.value.string_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'page_location'
      ), '')
    )                                                       AS page_location,
    
    LOWER(
      COALESCE((
        SELECT ep.value.string_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'page_title'
      ), '')
    )                                                       AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

session_flags AS (
  -- Mark, for every (user, session), whether the Home page and
  -- Checkout‑Confirmation page were seen
  SELECT
    user_pseudo_id,
    session_id,
    MAX(
      CASE
        -- Home page: exact URL of root store OR canonical home title
        WHEN page_location IN (
               'https://googlemerchandisestore.com/',
               'https://shop.googlemerchandisestore.com/'
             )
          OR page_title IN ('google online store','home')
        THEN 1 ELSE 0
      END
    ) AS has_home,
    MAX(
      CASE
        -- Checkout‑confirmation heuristics (URL or title contains keywords)
        WHEN (page_location LIKE '%/checkout%' AND page_location LIKE '%confirmation%')
          OR page_location LIKE '%/checkout%complete%'
          OR page_title   LIKE '%checkout confirmation%'
          OR page_title   LIKE '%order confirmation%'
          OR page_title   LIKE '%order complete%'
        THEN 1 ELSE 0
      END
    ) AS has_checkout
  FROM page_views
  WHERE session_id IS NOT NULL          -- keep sessions we can identify
  GROUP BY user_pseudo_id, session_id
),

metrics AS (
  SELECT
    COUNTIF(has_home = 1)                      AS sessions_with_home,
    COUNTIF(has_home = 1 AND has_checkout = 1) AS sessions_with_conversion
  FROM session_flags
)

SELECT
  sessions_with_conversion,
  sessions_with_home,
  ROUND(100 * sessions_with_conversion / sessions_with_home, 4) AS conversion_rate_percentage
FROM metrics;