-- Page with the 2nd-highest number of page views on
-- shop.googlemerchandisestore.com during December 2020
WITH raw_paths AS (
  SELECT
    -- extract the path for the target host and collapse duplicate “/”
    REGEXP_REPLACE(
      REGEXP_EXTRACT(
        (SELECT ep.value.string_value
         FROM UNNEST(event_params) ep
         WHERE ep.key = 'page_location'),
        r'https?://shop\.googlemerchandisestore\.com([^?#]*)'),
      r'/+','/') AS path_clean
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'      -- Dec-2020 tables
    AND event_name = 'page_view'                 -- only page views
),
page_views AS (
  SELECT
    IF(path_clean IS NULL OR path_clean = '', '/', path_clean) AS page_path
  FROM raw_paths
),
ranked AS (
  SELECT
    page_path,
    COUNT(*) AS page_views,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM page_views
  GROUP BY page_path
)
SELECT page_path
FROM ranked
WHERE rnk = 2;