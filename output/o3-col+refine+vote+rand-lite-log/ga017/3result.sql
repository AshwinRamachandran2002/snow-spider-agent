WITH top_page AS (
  -- find the single most-visited page in January 2021
  SELECT
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'
    AND event_name = 'page_view'
    AND ep.key = 'page_location'
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT
  COUNT(DISTINCT e.user_pseudo_id) AS distinct_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` AS e
     CROSS JOIN UNNEST(e.event_params) AS ep
JOIN top_page tp
  ON ep.key = 'page_location'
 AND ep.value.string_value = tp.page_location
WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'
  AND e.event_name = 'page_view';