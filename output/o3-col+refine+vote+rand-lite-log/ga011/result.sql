-- second–most-viewed cleaned page path on shop.googlemerchandisestore.com in Dec-2020
SELECT clean_path
FROM (
  SELECT
    REGEXP_REPLACE(                         -- collapse any double slashes in the path
      REGEXP_EXTRACT(ep.value.string_value,
                     r'^https?://[^/]+(.*)$'),  -- keep only the part after the domain
      r'//+', '/')                       AS clean_path,
    COUNT(*)                              AS total_pageviews,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
       UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key      = 'page_location'
    AND REGEXP_CONTAINS(ep.value.string_value,
                        r'^https?://shop\.googlemerchandisestore\.com')
  GROUP BY clean_path
)
WHERE rnk = 2;