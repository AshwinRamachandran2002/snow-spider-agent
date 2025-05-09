WITH base AS (
  SELECT event_params
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_date = '20210102'
    AND user_pseudo_id = '1402138.5184246691'
    AND event_name = 'page_view'
),
location_rows AS (
  SELECT
    ep.value.string_value AS page_location,
    event_params
  FROM base
  CROSS JOIN UNNEST(event_params) AS ep
  WHERE ep.key = 'page_location'
),
pages AS (
  SELECT
    lr.page_location,
    MAX(IF(ep.key = 'page_title', ep.value.string_value, NULL)) AS page_title
  FROM location_rows AS lr
  CROSS JOIN UNNEST(lr.event_params) AS ep
  GROUP BY lr.page_location
),
segments AS (
  SELECT
    page_title,
    page_location,
    SPLIT(page_location, '/') AS segs,
    LOWER(REGEXP_EXTRACT(page_location, r'[^/]+$')) AS last_seg
  FROM pages
),
classified AS (
  SELECT
    CASE
      WHEN ARRAY_LENGTH(segs) >= 5
           AND last_seg LIKE '%+%'
           AND (
                 LOWER(REPLACE(segs[OFFSET(3)], '+', ' ')) IN UNNEST([
                   'accessories','apparel','brands','campus collection','drinkware','electronics',
                   'google redesign','lifestyle','nest','new 2015 logo','notebooks journals','office',
                   'shop by brand','small goods','stationery','wearables'])
              OR LOWER(REPLACE(segs[OFFSET(4)], '+', ' ')) IN UNNEST([
                   'accessories','apparel','brands','campus collection','drinkware','electronics',
                   'google redesign','lifestyle','nest','new 2015 logo','notebooks journals','office',
                   'shop by brand','small goods','stationery','wearables'])
           )
        THEN 'PDP'
      WHEN ARRAY_LENGTH(segs) >= 5
           AND last_seg NOT LIKE '%+%'
           AND (
                 LOWER(REPLACE(segs[OFFSET(3)], '+', ' ')) IN UNNEST([
                   'accessories','apparel','brands','campus collection','drinkware','electronics',
                   'google redesign','lifestyle','nest','new 2015 logo','notebooks journals','office',
                   'shop by brand','small goods','stationery','wearables'])
              OR LOWER(REPLACE(segs[OFFSET(4)], '+', ' ')) IN UNNEST([
                   'accessories','apparel','brands','campus collection','drinkware','electronics',
                   'google redesign','lifestyle','nest','new 2015 logo','notebooks journals','office',
                   'shop by brand','small goods','stationery','wearables'])
           )
        THEN 'PLP'
      ELSE IFNULL(page_title, page_location)
    END AS page_name
  FROM segments
)
SELECT DISTINCT page_name
FROM classified
ORDER BY page_name;