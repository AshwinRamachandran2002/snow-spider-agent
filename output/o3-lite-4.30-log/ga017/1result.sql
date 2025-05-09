WITH jan_page_views AS (
  SELECT
    ep.value.string_value AS page_location,
    user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
    AND event_name = 'page_view'
    AND ep.key = 'page_location'
),
top_page AS (
  SELECT page_location
  FROM jan_page_views
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT
  COUNT(DISTINCT user_pseudo_id) AS distinct_user_count
FROM jan_page_views
JOIN top_page USING (page_location);