-- second‑most visited page (by page_view events) on shop.googlemerchandisestore.com in December‑2020
WITH dec_pageviews AS (
  SELECT
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
       UNNEST(event_params) ep
  WHERE event_name = 'page_view'
    AND ep.key     = 'page_location'
),

clean_paths AS (
  SELECT
    -- 1) keep only urls whose host is shop.googlemerchandisestore.com
    -- 2) take the path before any ? or # characters
    -- 3) collapse consecutive slashes to one
    REGEXP_REPLACE(                          -- step 3
      REGEXP_EXTRACT(                        -- step 2
        LOWER(page_location),
        r'https?://shop\.googlemerchandisestore\.com(/[^?#]*)'  -- step 1
      ),
      r'/{2,}',                              -- replace "//", "///", … with "/"
      '/'
    ) AS page_path
  FROM dec_pageviews
)

SELECT
  page_path,
  COUNT(*) AS total_page_views
FROM clean_paths
WHERE page_path IS NOT NULL
GROUP BY page_path
ORDER BY total_page_views DESC
LIMIT 1 OFFSET 1;   -- second‑highest