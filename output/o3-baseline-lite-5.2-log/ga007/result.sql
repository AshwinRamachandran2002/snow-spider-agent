/*  Percentage of Product‑Detail‑Page (PDP) views on 2‑Jan‑2021               */
WITH page_views AS (   -- 1. grab every page_view and its URL
  SELECT
    ( SELECT ep.value.string_value
      FROM   UNNEST(event_params) ep
      WHERE  ep.key = 'page_location'
      LIMIT  1 ) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
segments AS (          -- 2. split the URL path into segments
  SELECT
    page_location,
    SPLIT( REGEXP_EXTRACT(page_location, r'https?://[^/]+/(.*)'), '/' ) AS segs
  FROM page_views
  WHERE page_location IS NOT NULL
),
candidates AS (        -- 3. pick out the required segments
  SELECT
    page_location,
    segs,
    ARRAY_LENGTH(segs)                                  AS seg_len,
    segs[SAFE_OFFSET(3)]                                AS seg4,
    segs[SAFE_OFFSET(4)]                                AS seg5,
    ARRAY_REVERSE(segs)[SAFE_OFFSET(0)]                 AS last_seg
  FROM segments
),
flagged AS (           -- 4. test PDP conditions
  SELECT
    *,
    REGEXP_CONTAINS(
        REPLACE(LOWER(COALESCE(seg4,'')), '+', ' '),
        r'(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)'
    ) AS cat4_match,
    REGEXP_CONTAINS(
        REPLACE(LOWER(COALESCE(seg5,'')), '+', ' '),
        r'(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)'
    ) AS cat5_match
  FROM candidates
)
-- 5. calculate percentage
SELECT
  COUNTIF(
      seg_len >= 5
      AND STRPOS(last_seg, '+') > 0
      AND (cat4_match OR cat5_match)
  )                                           AS pdp_page_views,
  COUNT(*)                                    AS total_page_views,
  ROUND( COUNTIF(
            seg_len >= 5
            AND STRPOS(last_seg, '+') > 0
            AND (cat4_match OR cat5_match)
        ) / COUNT(*) * 100 , 4)               AS pdp_page_view_percentage
FROM flagged;