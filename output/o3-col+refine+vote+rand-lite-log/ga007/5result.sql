-- Percentage of page-view events on 2-Jan-2021 that were PDPs
WITH page_views AS (
  SELECT
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
       UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key      = 'page_location'
),
classified AS (
  SELECT
    page_location,
    CASE
      WHEN ARRAY_LENGTH(segs) >= 5
           -- last segment contains '+'  → possible product detail
           AND REGEXP_CONTAINS(LOWER(segs[ORDINAL(ARRAY_LENGTH(segs))]), r'\+')
           -- 4th or 5th segment contains one of the allowed categories
           AND (
                 REGEXP_CONTAINS(
                   LOWER(segs[ORDINAL(4)]),
                   r'accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables'
                 )
                 OR
                 REGEXP_CONTAINS(
                   LOWER(segs[ORDINAL(5)]),
                   r'accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables'
                 )
               )
        THEN TRUE
      ELSE FALSE
    END AS is_pdp
  FROM (
    SELECT
      page_location,
      SPLIT(REGEXP_REPLACE(page_location, r'^https?://', ''), '/') AS segs
    FROM page_views
  )
)
SELECT
  ROUND(100 * SUM(CASE WHEN is_pdp THEN 1 ELSE 0 END) / COUNT(*), 4) AS pdp_percentage
FROM classified;