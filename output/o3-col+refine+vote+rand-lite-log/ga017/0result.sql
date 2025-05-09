WITH pageviews AS (
  SELECT
    ep.value.string_value AS page_location,
    COUNT(*)              AS pv
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` t,
       UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'page_view'
    AND ep.key       = 'page_location'
  GROUP BY page_location
),
top_page AS (
  SELECT page_location
  FROM pageviews
  ORDER BY pv DESC
  LIMIT 1
)
SELECT
  COUNT(DISTINCT t.user_pseudo_id) AS distinct_users_on_most_viewed_page
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` t
JOIN UNNEST(t.event_params) AS ep
ON TRUE
JOIN top_page tp
ON ep.value.string_value = tp.page_location
WHERE t.event_name = 'page_view'
  AND ep.key = 'page_location';