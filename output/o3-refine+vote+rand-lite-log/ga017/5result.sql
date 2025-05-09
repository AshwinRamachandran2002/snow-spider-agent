-- distinct users who viewed the single most‑visited page in January 2021
WITH jan_page_views AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`
  WHERE event_name = 'page_view'
),
most_visited_page AS (
  SELECT page_location
  FROM jan_page_views
  WHERE page_location IS NOT NULL
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1            -- the single page with the highest number of views
)
SELECT COUNT(DISTINCT user_pseudo_id) AS distinct_users
FROM jan_page_views
JOIN most_visited_page USING (page_location);