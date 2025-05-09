WITH most_visited_page AS (
  SELECT
    ep.value.string_value AS page_location
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e,
    UNNEST(e.event_params) AS ep
  WHERE
    e.event_name = 'page_view'
    AND ep.key = 'page_location'
    AND _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
  GROUP BY
    page_location
  ORDER BY
    COUNT(*) DESC
  LIMIT 1
)
SELECT
  COUNT(DISTINCT e.user_pseudo_id) AS Number_of_Distinct_Users
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e,
  UNNEST(e.event_params) AS ep,
  most_visited_page AS mvp
WHERE
  e.event_name = 'page_view'
  AND ep.key = 'page_location'
  AND ep.value.string_value = mvp.page_location
  AND _TABLE_SUFFIX BETWEEN '20210101' AND '20210131';