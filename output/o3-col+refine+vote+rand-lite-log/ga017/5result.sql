WITH jan_page_views AS (
  SELECT
    p.value.string_value AS page_location,
    user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`,
       UNNEST(event_params) AS p
  WHERE event_name = 'page_view'
    AND p.key = 'page_location'
),
most_popular AS (
  SELECT page_location
  FROM jan_page_views
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT
  COUNT(DISTINCT user_pseudo_id) AS distinct_users_most_visited_page
FROM jan_page_views
WHERE page_location IN (SELECT page_location FROM most_popular);