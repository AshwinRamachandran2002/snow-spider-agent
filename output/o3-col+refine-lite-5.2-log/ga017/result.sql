-- number of distinct users who viewed the most‑frequently visited page in Jan‑2021
WITH page_counts AS (
  SELECT
    ep.value.string_value AS page_location,
    COUNT(*) AS view_count
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` e,
    UNNEST(e.event_params) ep
  WHERE
    e.event_name = 'page_view'
    AND ep.key = 'page_location'
  GROUP BY
    page_location
),
top_page AS (
  SELECT
    page_location
  FROM
    page_counts
  ORDER BY
    view_count DESC
  LIMIT 1
)
SELECT
  COUNT(DISTINCT e.user_pseudo_id) AS distinct_users_viewed_top_page
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*` e
JOIN
  UNNEST(e.event_params) ep
ON
  TRUE
JOIN
  top_page tp
ON
  ep.value.string_value = tp.page_location
WHERE
  e.event_name = 'page_view'
  AND ep.key = 'page_location';