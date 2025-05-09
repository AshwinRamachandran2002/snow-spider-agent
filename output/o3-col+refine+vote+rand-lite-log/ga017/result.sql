WITH jan_pageviews AS (
  -- isolate every page_view in January 2021 and grab its URL + user
  SELECT
    ep.value.string_value AS page_location,
    e.user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` AS e
  CROSS JOIN UNNEST(e.event_params) AS ep
  WHERE e.event_name = 'page_view'
    AND ep.key = 'page_location'
),
top_page AS (
  -- find the single most-visited page in that month
  SELECT page_location
  FROM jan_pageviews
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
-- count how many distinct users viewed that top page
SELECT COUNT(DISTINCT user_pseudo_id) AS distinct_users_who_viewed_top_page
FROM jan_pageviews
WHERE page_location IN (SELECT page_location FROM top_page);