WITH categories AS (
  SELECT ARRAY<STRING>[
    'accessories','apparel','brands','campus collection','drinkware','electronics',
    'google redesign','lifestyle','nest','new 2015 logo','notebooks journals',
    'office','shop by brand','small goods','stationery','wearables'
  ] AS cat_list
),
page_views AS (
  -- all page‑view events on 2021‑01‑02 with their page_location URL
  SELECT
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` e
  CROSS JOIN UNNEST(e.event_params) ep
  WHERE e.event_name = 'page_view'
    AND ep.key        = 'page_location'
),
pdp_flagged AS (
  -- add URL segments and bring in the category list
  SELECT
    pv.page_location,
    SPLIT(REGEXP_REPLACE(pv.page_location, r'^https?://', ''), '/') AS segments,
    cat.cat_list
  FROM page_views pv
  CROSS JOIN categories cat
)
SELECT
  -- final percentage (4‑decimal precision)
  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(
        ARRAY_LENGTH(segments) >= 5                                           -- ≥5 segments
        AND REGEXP_CONTAINS(segments[OFFSET(ARRAY_LENGTH(segments)-1)], r'\+') -- '+' in last segment
        AND (
              LOWER(REPLACE(IFNULL(segments[SAFE_OFFSET(3)],''), '+', ' ')) IN UNNEST(cat_list)
           OR LOWER(REPLACE(IFNULL(segments[SAFE_OFFSET(4)],''), '+', ' ')) IN UNNEST(cat_list)
        )                                                                     -- 4th/5th segment is category
      ),
      COUNT(*)
    )
  , 4) AS pdp_page_view_percentage
FROM pdp_flagged;