-- Navigation flow (PLP / PDP / title) for user 1362228.4966015575 on 28-Jan-2021
WITH base AS (
  SELECT
    event_timestamp,
    (SELECT v.value.string_value
     FROM UNNEST(event_params) AS v
     WHERE v.key = 'page_location')                                AS page_url,
    (SELECT v.value.string_value
     FROM UNNEST(event_params) AS v
     WHERE v.key = 'page_title')                                   AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE user_pseudo_id = '1362228.4966015575'
    AND event_name     = 'page_view'
),
parsed AS (
  SELECT
    event_timestamp,
    page_title,
    SPLIT(REGEXP_REPLACE(page_url, r'https?://', ''), '/') AS parts
  FROM base
),
classified AS (
  SELECT
    event_timestamp,
    CASE
      -- Product Detail Page  (PDP)
      WHEN ARRAY_LENGTH(parts) >= 5
           AND (
                LOWER(REPLACE(parts[OFFSET(3)], '+', ' ')) IN (
                  'accessories','apparel','brands','campus collection','drinkware','electronics',
                  'google redesign','lifestyle','nest','new 2015 logo','notebooks journals',
                  'office','shop by brand','small goods','stationery','wearables'
                )
             OR LOWER(REPLACE(parts[OFFSET(4)], '+', ' ')) IN (
                  'accessories','apparel','brands','campus collection','drinkware','electronics',
                  'google redesign','lifestyle','nest','new 2015 logo','notebooks journals',
                  'office','shop by brand','small goods','stationery','wearables'
                )
           )
           AND REGEXP_CONTAINS(parts[OFFSET(ARRAY_LENGTH(parts)-1)], r'\+')
        THEN 'PDP'

      -- Product Listing Page (PLP)
      WHEN ARRAY_LENGTH(parts) >= 5
           AND (
                LOWER(REPLACE(parts[OFFSET(3)], '+', ' ')) IN (
                  'accessories','apparel','brands','campus collection','drinkware','electronics',
                  'google redesign','lifestyle','nest','new 2015 logo','notebooks journals',
                  'office','shop by brand','small goods','stationery','wearables'
                )
             OR LOWER(REPLACE(parts[OFFSET(4)], '+', ' ')) IN (
                  'accessories','apparel','brands','campus collection','drinkware','electronics',
                  'google redesign','lifestyle','nest','new 2015 logo','notebooks journals',
                  'office','shop by brand','small goods','stationery','wearables'
                )
           )
           AND NOT REGEXP_CONTAINS(parts[OFFSET(3)], r'\+')
           AND NOT REGEXP_CONTAINS(parts[OFFSET(4)], r'\+')
        THEN 'PLP'

      -- Anything else: keep the original title
      ELSE page_title
    END AS step_label
  FROM parsed
),
dedup AS (
  SELECT
    event_timestamp,
    step_label,
    LAG(step_label) OVER (ORDER BY event_timestamp) AS prev_label
  FROM classified
)
SELECT
  STRING_AGG(step_label, '>>' ORDER BY event_timestamp) AS navigation_flow
FROM dedup
WHERE prev_label IS NULL OR step_label <> prev_label;