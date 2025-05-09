WITH pageviews AS (
  SELECT
    -- 1. isolate the path  2. collapse duplicate “/”  3. drop trailing “/”
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_EXTRACT(ep.value.string_value, r'^[^:]+://[^/]+(/[^?#]*)'),
        r'//+', '/'
      ),
      r'/$', ''
    ) AS clean_path,
    COUNT(*) AS pv
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` t,
       UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'page_view'
    AND ep.key = 'page_location'
    AND NET.HOST(ep.value.string_value) = 'shop.googlemerchandisestore.com'
  GROUP BY clean_path
),
ranked AS (
  SELECT
    clean_path,
    pv,
    ROW_NUMBER() OVER (ORDER BY pv DESC) AS rn
  FROM pageviews
)
SELECT
  clean_path AS second_most_viewed_page,
  pv         AS page_views
FROM ranked
WHERE rn = 2;