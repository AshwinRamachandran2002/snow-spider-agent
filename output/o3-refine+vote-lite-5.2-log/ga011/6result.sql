WITH page_views AS (
  SELECT
    -- remove protocol & domain, collapse multiple slashes, drop trailing slash
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(ep.value.string_value, r'^https?://[^/]+', ''),  -- keep only the path
        r'/+', '/'),                                                    -- collapse duplicate /
      r'/$',''                                                          -- remove trailing /
    ) AS page_path,
    COUNT(*) AS views
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  ,    UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key = 'page_location'
    AND ep.value.string_value IS NOT NULL
    AND ep.value.string_value LIKE '%shop.googlemerchandisestore.com%'   -- only the target site
  GROUP BY page_path
  HAVING page_path <> ''                                                 -- ignore empty paths
), ranked AS (
  SELECT
    page_path,
    views,
    ROW_NUMBER() OVER (ORDER BY views DESC) AS rn
  FROM page_views
)
SELECT page_path
FROM ranked
WHERE rn = 2;