/* second‑most viewed page on shop.googlemerchandisestore.com in Dec‑2020 */
SELECT path
FROM (
  SELECT
    REGEXP_REPLACE(                          -- collapse multiple slashes
      IFNULL(                                -- extract path; default to “/”
        REGEXP_EXTRACT(pl, r'^[a-zA-Z]+://[^/]+(/[^?#]*)'),
        '/'
      ),
      r'/+',
      '/'
    ) AS path,
    COUNT(*) AS page_views
  FROM (
    -- pull the page_location parameter from each page_view event
    SELECT
      ( SELECT ep.value.string_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'page_location'
        LIMIT 1 ) AS pl
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
    WHERE event_name = 'page_view'
  )
  -- keep only the store’s domain
  WHERE pl LIKE 'https://shop.googlemerchandisestore.com%'
     OR pl LIKE 'http://shop.googlemerchandisestore.com%'
  GROUP BY path
)
ORDER BY page_views DESC, path
LIMIT 1 OFFSET 1;      -- 2nd highest (skip the top row)