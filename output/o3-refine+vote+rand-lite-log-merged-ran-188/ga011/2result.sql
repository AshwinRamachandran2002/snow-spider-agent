WITH page_views AS (
  SELECT
    -- remove the domain, then collapse duplicate slashes in the remaining path
    IF(
      REGEXP_REPLACE(
        REGEXP_REPLACE(ev.value.string_value,
          r'^https?://shop\.googlemerchandisestore\.com', ''),           -- strip domain
        r'/+', '/') = '',
      '/',                                                              -- root path
      REGEXP_REPLACE(
        REGEXP_REPLACE(ev.value.string_value,
          r'^https?://shop\.googlemerchandisestore\.com', ''),
        r'/+', '/')
    ) AS page_path,
    COUNT(*) AS total_views
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` AS t
  CROSS JOIN UNNEST(t.event_params) AS ev
  WHERE t.event_name = 'page_view'
    AND ev.key = 'page_location'
    AND (STARTS_WITH(ev.value.string_value, 'https://shop.googlemerchandisestore.com')
         OR STARTS_WITH(ev.value.string_value, 'http://shop.googlemerchandisestore.com'))
  GROUP BY page_path
),
ranked AS (
  SELECT
    page_path,
    total_views,
    ROW_NUMBER() OVER (ORDER BY total_views DESC, page_path) AS rn
  FROM page_views
)
SELECT
  page_path,
  total_views
FROM ranked
WHERE rn = 2;