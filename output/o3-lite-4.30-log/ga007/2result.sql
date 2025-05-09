WITH page_views AS (
  SELECT
    ep.value.string_value AS page_url,
    SPLIT(ep.value.string_value, '/') AS parts
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t
  CROSS JOIN UNNEST(t.event_params) AS ep
  WHERE t.event_date = '20210102'
    AND t.event_name = 'page_view'
    AND ep.key = 'page_location'
),
filtered AS (
  SELECT
    page_url,
    parts,
    parts[SAFE_OFFSET(3)] AS seg4,
    parts[SAFE_OFFSET(4)] AS seg5,
    parts[SAFE_OFFSET(ARRAY_LENGTH(parts) - 1)] AS last_seg
  FROM page_views
  WHERE ARRAY_LENGTH(parts) >= 5
    AND (
      LOWER(parts[SAFE_OFFSET(3)]) IN (
        'accessories','apparel','brands','campus collection','drinkware','electronics',
        'google redesign','lifestyle','nest','new 2015 logo','notebooks journals','office',
        'shop by brand','small goods','stationery','wearables'
      )
      OR LOWER(parts[SAFE_OFFSET(4)]) IN (
        'accessories','apparel','brands','campus collection','drinkware','electronics',
        'google redesign','lifestyle','nest','new 2015 logo','notebooks journals','office',
        'shop by brand','small goods','stationery','wearables'
      )
    )
),
classified AS (
  SELECT
    page_url,
    CASE
      WHEN STRPOS(last_seg, '+') > -1 THEN 'PDP'
      WHEN STRPOS(seg4, '+') > -1 OR STRPOS(seg5, '+') > -1 THEN 'EXCLUDE'
      ELSE 'PLP'
    END AS page_type
  FROM filtered
),
agg AS (
  SELECT
    SUM(CASE WHEN page_type = 'PDP' THEN 1 ELSE 0 END) AS pdp_views,
    SUM(CASE WHEN page_type IN ('PDP', 'PLP') THEN 1 ELSE 0 END) AS total_views
  FROM classified
)
SELECT
  ROUND(pdp_views / total_views * 100, 4) AS percentage_pdp_page_views
FROM agg;