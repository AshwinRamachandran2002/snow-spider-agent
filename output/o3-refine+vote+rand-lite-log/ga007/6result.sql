-- Percentage of page‑view events that were PDPs on 2‑Jan‑2021
WITH page_views AS (
  -- Grab the URL of every page_view on 2021‑01‑02
  SELECT
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
       UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key      = 'page_location'
    AND ep.value.string_value IS NOT NULL
),
classified AS (
  -- Split the URL into its “/” segments
  SELECT
    page_location,
    SPLIT(page_location, '/') AS segments
  FROM page_views
),
pdp_flagged AS (
  -- Flag each page_view as PDP (=1) or not (=0)
  SELECT
    CASE
      WHEN
        -- at least five “/” segments
        ARRAY_LENGTH(segments) >= 5
        -- last segment contains a '+' sign
        AND REGEXP_CONTAINS(LOWER(segments[OFFSET(ARRAY_LENGTH(segments)-1)]),
                             r'\+')
        -- 4th or 5th segment is one of the recognised categories
        AND (
             (ARRAY_LENGTH(segments) > 3 AND
              LOWER(segments[OFFSET(3)])
              IN UNNEST([
                'accessories','apparel','brands','campus+collection','drinkware',
                'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                'notebooks+journals','office','shop+by+brand','small+goods',
                'stationery','wearables'
              ]))
          OR (ARRAY_LENGTH(segments) > 4 AND
              LOWER(segments[OFFSET(4)])
              IN UNNEST([
                'accessories','apparel','brands','campus+collection','drinkware',
                'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                'notebooks+journals','office','shop+by+brand','small+goods',
                'stationery','wearables'
              ]))
            )
      THEN 1 ELSE 0
    END AS is_pdp
  FROM classified
)
SELECT
  ROUND( SAFE_DIVIDE(SUM(is_pdp), COUNT(*)) * 100 , 4) AS pdp_page_view_percentage
FROM pdp_flagged;