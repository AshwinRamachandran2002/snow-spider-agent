SELECT
  REGEXP_EXTRACT(page_location, r'^https?://[^/]+(/[^?]*)') AS page_path,
  page_title,
  COUNT(*) AS pageviews
FROM (
  SELECT
    (SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_location' LIMIT 1) AS page_location,
    (SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_title' LIMIT 1) AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'page_view'
)
WHERE
  page_location LIKE '%shop.googlemerchandisestore.com%'
GROUP BY
  page_path,
  page_title
ORDER BY
  pageviews DESC
LIMIT 1;