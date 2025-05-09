-- Page path with the 2nd-highest total page views on shop.googlemerchandisestore.com in Dec-2020
SELECT
  cleaned_path AS second_most_viewed_page,
  page_views
FROM (
  SELECT
    REGEXP_REPLACE(
      REGEXP_EXTRACT(ep.value.string_value, r'^https?://[^/]+(/[^?#]*)'),
      r'//+', '/')                 AS cleaned_path,
    COUNT(*)                       AS page_views
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
       UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key = 'page_location'
    AND STARTS_WITH(ep.value.string_value,
                    'https://shop.googlemerchandisestore.com')
  GROUP BY cleaned_path
)
ORDER BY page_views DESC
LIMIT 1 OFFSET 1;