WITH most_visited_page AS (
  SELECT ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` AS t,
  UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'page_view' AND ep.key = 'page_location'
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT COUNT(DISTINCT t.user_pseudo_id) AS Number_of_Distinct_Users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` AS t,
UNNEST(t.event_params) AS ep,
most_visited_page
WHERE t.event_name = 'page_view'
  AND ep.key = 'page_location'
  AND ep.value.string_value = most_visited_page.page_location;