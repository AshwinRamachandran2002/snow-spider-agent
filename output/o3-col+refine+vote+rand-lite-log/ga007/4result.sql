-- Percentage of Product-Detail-Page (PDP) views among all page_view events
-- for 2-Jan-2021  (table events_20210102)

WITH page_views AS (
  SELECT
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
       UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key   = 'page_location'
),

classified AS (
  SELECT
    page_location,
    -- ----------------------- PDP rule -----------------------
    --  1. ≥ 5 path segments   2. '+' in last segment
    --  3. recognised category in 4th OR 5th segment (case-insensitive)
    (
      ARRAY_LENGTH(SPLIT(SUBSTR(page_location, STRPOS(page_location,'://') + 3), '/')) >= 5
      AND REGEXP_CONTAINS(
            LOWER(ARRAY_REVERSE(
                     SPLIT(SUBSTR(page_location, STRPOS(page_location,'://') + 3), '/')
                 )[OFFSET(0)]), r'\+')
      AND (
           LOWER(SPLIT(SUBSTR(page_location, STRPOS(page_location,'://') + 3), '/')[OFFSET(3)])
               IN ('accessories','apparel','brands','campus+collection','drinkware',
                   'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                   'notebooks+journals','office','shop+by+brand','small+goods',
                   'stationery','wearables')
        OR LOWER(SPLIT(SUBSTR(page_location, STRPOS(page_location,'://') + 3), '/')[OFFSET(4)])
               IN ('accessories','apparel','brands','campus+collection','drinkware',
                   'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                   'notebooks+journals','office','shop+by+brand','small+goods',
                   'stationery','wearables')
          )
    ) AS is_pdp
  FROM page_views
)

SELECT
  ROUND(100 * SUM(CASE WHEN is_pdp THEN 1 ELSE 0 END) / COUNT(*), 4) 
      AS pdp_percentage_of_pageviews
FROM classified;