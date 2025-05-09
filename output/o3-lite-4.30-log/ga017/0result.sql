WITH page_view_events AS (
  SELECT
    user_pseudo_id,
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`,
       UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key = 'page_location'
    AND ep.value.string_value IS NOT NULL
),
most_visited_page AS (
  SELECT
    page_location
  FROM page_view_events
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT
  COUNT(DISTINCT user_pseudo_id) AS distinct_user_count
FROM page_view_events
WHERE page_location = (SELECT page_location FROM most_visited_page);