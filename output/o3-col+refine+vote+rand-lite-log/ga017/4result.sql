-- Count of distinct users who viewed January-2021’s most-visited page
WITH top_page AS (
  SELECT
    p.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` AS e
  CROSS JOIN UNNEST(e.event_params) AS p
  WHERE e.event_name = 'page_view'
    AND p.key = 'page_location'
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1                     -- the single most-visited page
)
SELECT
  COUNT(DISTINCT e.user_pseudo_id) AS distinct_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` AS e
CROSS JOIN UNNEST(e.event_params) AS p
JOIN top_page t
  ON p.key = 'page_location'
 AND p.value.string_value = t.page_location
WHERE e.event_name = 'page_view';