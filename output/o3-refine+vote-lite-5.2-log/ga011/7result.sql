WITH december_pageviews AS (
  SELECT
    -- extract path after the host and collapse any duplicate slashes
    REGEXP_REPLACE(
      REGEXP_EXTRACT(p.value.string_value,
                     r'https?://shop\.googlemerchandisestore\.com(/[^?#]*)'),
      r'/+', '/') AS page_path
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
  CROSS JOIN UNNEST(e.event_params) AS p
  WHERE
    _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'  -- December 2020
    AND e.event_name = 'page_view'
    AND p.key = 'page_location'
    AND p.value.string_value IS NOT NULL
)

SELECT page_path
FROM (
  SELECT
    page_path,
    COUNT(*) AS page_views,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM december_pageviews
  WHERE page_path IS NOT NULL AND page_path <> ''
  GROUP BY page_path
)
WHERE rnk = 2       -- second‑highest
LIMIT 1;