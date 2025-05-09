/* second‑most viewed page (cleaned path) on shop.googlemerchandisestore.com in Dec‑2020 */
SELECT
  clean_path AS page_path,
  page_views
FROM (
  /* aggregate page views by cleaned path */
  SELECT
    REGEXP_REPLACE(                                   -- 2) remove trailing slash (except root)
      REGEXP_REPLACE(                                 -- 1) collapse multiple slashes
        IFNULL(
          REGEXP_EXTRACT(                             -- extract path after domain
            LOWER(ep.value.string_value),
            r'https?://shop\.googlemerchandisestore\.com(/[^?#]*)'
          ),
          '/'
        ),
        r'/+', '/'
      ),
      r'/$', ''
    ) AS clean_path,
    COUNT(*) AS page_views
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  CROSS JOIN UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'        -- December‑2020 tables
    AND event_name = 'page_view'
    AND ep.key = 'page_location'
    AND ep.value.string_value IS NOT NULL
    AND LOWER(ep.value.string_value) LIKE 'https://shop.googlemerchandisestore.com%'
  GROUP BY clean_path
)
ORDER BY page_views DESC, page_path
LIMIT 1 OFFSET 1;      -- 2nd highest