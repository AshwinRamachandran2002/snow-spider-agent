WITH jan_page_views AS (
  -- All page_view events in January 2021
  SELECT
    user_pseudo_id,
    /* pull the page URL (page_location) from the repeated event_params array */
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`
  WHERE event_name = 'page_view'
),
page_view_counts AS (
  -- How many times each page was viewed
  SELECT
    page_location,
    COUNT(*) AS views
  FROM jan_page_views
  WHERE page_location IS NOT NULL
  GROUP BY page_location
),
most_viewed_page AS (
  -- Identify the single most‑viewed page
  SELECT page_location
  FROM page_view_counts
  ORDER BY views DESC, page_location   -- tie‑breaker by URL
  LIMIT 1
)
SELECT
  COUNT(DISTINCT user_pseudo_id) AS distinct_users
FROM jan_page_views
WHERE page_location = (SELECT page_location FROM most_viewed_page);