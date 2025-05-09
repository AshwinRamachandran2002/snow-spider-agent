-- Page with the 2nd-highest number of December-2020 page views
WITH page_paths AS (
  SELECT
    -- 1) grab the part after the domain
    -- 2) collapse any double “//”
    -- 3) drop a trailing “/”
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_EXTRACT(p.value.string_value,
                       r'https?://shop\.googlemerchandisestore\.com(/.*)'),
        r'/{2,}', '/'),
      r'/$', ''
    ) AS clean_path
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  CROSS JOIN UNNEST(event_params) AS p
  WHERE event_name = 'page_view'
    AND p.key = 'page_location'
    AND STARTS_WITH(p.value.string_value,
                    'https://shop.googlemerchandisestore.com')
)
SELECT clean_path
FROM (
  SELECT
    clean_path,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM page_paths
  GROUP BY clean_path
)
WHERE rnk = 2
LIMIT 1;