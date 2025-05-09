WITH paths AS (
  SELECT
    -- 1) extract the URL path
    -- 2) collapse multiple “/”
    -- 3) remove all trailing “/”
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        COALESCE(
          REGEXP_EXTRACT(p.value.string_value,
                         r'^https?://[^/]+(/[^?#]*)'),
          '/'
        ),
        r'/{2,}', '/'
      ),
      r'/+$',
      ''
    ) AS tidy
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  CROSS JOIN UNNEST(event_params) AS p
  WHERE event_name = 'page_view'
    AND p.key = 'page_location'
    AND REGEXP_EXTRACT(p.value.string_value,
                       r'^https?://([^/]+)') = 'shop.googlemerchandisestore.com'
),
cleaned AS (
  SELECT
    CASE WHEN tidy = '' THEN '/' ELSE tidy END AS page_path
  FROM paths
),
agg AS (
  SELECT
    page_path,
    COUNT(*) AS page_views
  FROM cleaned
  GROUP BY page_path
)
SELECT page_path
FROM (
  SELECT
    page_path,
    page_views,
    ROW_NUMBER() OVER (ORDER BY page_views DESC, page_path) AS rn
  FROM agg
)
WHERE rn = 2;