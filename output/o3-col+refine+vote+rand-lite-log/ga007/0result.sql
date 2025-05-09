WITH page_views AS (
  SELECT
    SPLIT(
      REGEXP_REPLACE(ep.value.string_value, r'^https?://[^/]+/', ''), 
      '/'
    ) AS seg
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t,
       UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'page_view'
    AND ep.key = 'page_location'
),
total AS (
  SELECT COUNT(*) AS total_views
  FROM page_views
),
pdp AS (
  SELECT COUNT(*) AS pdp_views
  FROM page_views
  WHERE ARRAY_LENGTH(seg) >= 5
    AND REGEXP_CONTAINS(seg[ORDINAL(ARRAY_LENGTH(seg))], r'\+')
    AND (
         LOWER(REGEXP_REPLACE(seg[ORDINAL(4)], r'\+', ' ')) IN UNNEST([
           'accessories','apparel','brands','campus collection','drinkware','electronics',
           'google redesign','lifestyle','nest','new 2015 logo','notebooks journals',
           'office','shop by brand','small goods','stationery','wearables'
         ])
      OR LOWER(REGEXP_REPLACE(seg[ORDINAL(5)], r'\+', ' ')) IN UNNEST([
           'accessories','apparel','brands','campus collection','drinkware','electronics',
           'google redesign','lifestyle','nest','new 2015 logo','notebooks journals',
           'office','shop by brand','small goods','stationery','wearables'
         ])
    )
)
SELECT
  100 * SAFE_DIVIDE(pdp_views, total_views) AS percentage_of_PDP_page_views
FROM pdp, total;