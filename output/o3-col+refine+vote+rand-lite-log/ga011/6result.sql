-- Second-highest viewed page (cleaned path) on shop.googlemerchandisestore.com in Dec-2020
SELECT
  clean_path AS second_most_viewed_page
FROM (
  SELECT
    REGEXP_REPLACE(                          -- collapse multiple slashes
      REGEXP_EXTRACT(
        ep.value.string_value,
        r'^https?://shop\.googlemerchandisestore\.com/?(.*)$'  -- strip protocol & domain
      ),
      r'/+', '/'
    )                       AS clean_path,
    COUNT(*)                AS views,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
        UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'          -- 1-31 Dec 2020
    AND event_name = 'page_view'                     -- page-view events only
    AND ep.key = 'page_location'                     -- URL parameter
    AND ep.value.string_value LIKE
        'https://shop.googlemerchandisestore.com/%'  -- required host
  GROUP BY clean_path
)
WHERE rnk = 2;