WITH page_counts AS (
  SELECT
    -- 1. take everything after the domain
    -- 2. collapse duplicated slashes (e.g. "///" -> "/")
    IFNULL(
      REGEXP_REPLACE(
        REGEXP_EXTRACT(ep.value.string_value, r'https?://[^/]+(/.*)'),
        r'/{2,}',
        '/'
      ),
      '/'                                  -- home page when no path exists
    ) AS page_path,
    COUNT(*) AS page_views
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  CROSS JOIN UNNEST(event_params) AS ep
  WHERE
    event_name = 'page_view'
    AND ep.key  = 'page_location'
    AND REGEXP_EXTRACT(ep.value.string_value, r'https?://([^/]+)') = 'shop.googlemerchandisestore.com'
  GROUP BY
    page_path
)
SELECT
  page_path
FROM
  page_counts
ORDER BY
  page_views DESC,          -- highest page‑viewed pages first
  page_path                 -- tie‑breaker
LIMIT 1
OFFSET 1;                    -- “second highest” record