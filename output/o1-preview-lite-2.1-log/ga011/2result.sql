SELECT
  clean_page_path,
  page_views
FROM (
  SELECT
    REGEXP_REPLACE(
      SPLIT(
        (SELECT value.string_value
         FROM UNNEST(event_params)
         WHERE key = 'page_location'),
        'shop.googlemerchandisestore.com'
      )[SAFE_OFFSET(1)],
      r'/+|\?.*',
      '/'
    ) AS clean_page_path,
    COUNT(*) AS page_views,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rank
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'page_view'
    AND event_date BETWEEN '20201201' AND '20201231'
    AND (SELECT value.string_value
         FROM UNNEST(event_params)
         WHERE key = 'page_location') LIKE '%shop.googlemerchandisestore.com%'
  GROUP BY clean_page_path
)
WHERE rank = 2;