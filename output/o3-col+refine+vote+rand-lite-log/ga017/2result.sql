WITH top_page AS (
  SELECT
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` AS t
  CROSS JOIN UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'page_view'
    AND ep.key = 'page_location'
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1                 -- most frequently visited page
)
SELECT
  COUNT(DISTINCT t.user_pseudo_id) AS distinct_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` AS t
CROSS JOIN UNNEST(t.event_params) AS ep
JOIN top_page tp
  ON ep.value.string_value = tp.page_location
WHERE t.event_name = 'page_view'
  AND ep.key = 'page_location';