-- Percentage of page‑view events that were PDPs on 2‑Jan‑2021
WITH pageviews AS (
  SELECT
    ep.value.string_value AS page_location,
    SPLIT(ep.value.string_value, '/') AS segments
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t
  CROSS JOIN UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'page_view'
    AND ep.key = 'page_location'
),
classified AS (
  SELECT
    CASE
      WHEN ARRAY_LENGTH(segments) >= 6
       AND REGEXP_CONTAINS(segments[SAFE_OFFSET(ARRAY_LENGTH(segments) - 1)], r'\+')
       AND (
            REGEXP_CONTAINS(
                LOWER(REPLACE(segments[SAFE_OFFSET(3)], '+', ' ')),
                r'accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables')
        OR  REGEXP_CONTAINS(
                LOWER(REPLACE(segments[SAFE_OFFSET(4)], '+', ' ')),
                r'accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables')
          )
      THEN 1 ELSE 0
    END AS is_pdp
  FROM pageviews
)
SELECT
  COUNTIF(is_pdp = 1) AS pdp_page_views,
  COUNT(*)            AS total_page_views,
  ROUND(100 * COUNTIF(is_pdp = 1) / COUNT(*), 2) AS pdp_percentage
FROM classified;