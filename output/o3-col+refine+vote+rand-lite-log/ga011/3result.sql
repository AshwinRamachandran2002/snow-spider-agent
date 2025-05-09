WITH page_hits AS (
  -- pull each page_view’s cleaned path for December-2020
  SELECT
    REGEXP_REPLACE(
      REGEXP_EXTRACT(ep.value.string_value, r'https?://[^/]+(/.*)'),
      r'//+', '/')                         AS page_path
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
       UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key = 'page_location'
    -- keep only the desired host
    AND REGEXP_EXTRACT(ep.value.string_value, r'https?://([^/]+)') =
        'shop.googlemerchandisestore.com'
)
SELECT
  page_path,
  COUNT(*) AS page_views
FROM page_hits
GROUP BY page_path
-- second-highest by total views
QUALIFY DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) = 2;