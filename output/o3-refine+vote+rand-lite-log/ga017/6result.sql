WITH jan_page_views AS (
  -- All page_view events in January 2021
  SELECT
    user_pseudo_id,
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) AS ep
     WHERE ep.key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`
  WHERE event_name = 'page_view'
),
most_viewed_page AS (
  -- Identify the single most‑visited page (by URL)
  SELECT page_location
  FROM jan_page_views
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
-- Count distinct users who viewed that page
SELECT COUNT(DISTINCT user_pseudo_id) AS distinct_users
FROM jan_page_views
WHERE page_location = (SELECT page_location FROM most_viewed_page);