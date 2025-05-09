/* Navigation flow (page-view only) for user 1362228.4966015575 on 2021-01-28  */
WITH pageviews AS (   -- 1. pull URL & title of every page_view hit
  SELECT
    event_timestamp,
    MAX(CASE WHEN ep.key = 'page_location' THEN ep.value.string_value END) AS page_location,
    MAX(CASE WHEN ep.key = 'page_title'    THEN ep.value.string_value END) AS page_title
  FROM   `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`,
         UNNEST(event_params) AS ep
  WHERE  user_pseudo_id = '1362228.4966015575'
    AND  event_name     = 'page_view'
  GROUP  BY event_timestamp
),

classified AS (       -- 2. turn every row into PDP / PLP / original title
  SELECT
    event_timestamp,
    CASE
      -- ------------ PDP ------------
      WHEN ARRAY_LENGTH(SPLIT(REGEXP_REPLACE(page_location,r'^https?://[^/]+/',''),'/')) >= 5
           AND (
                REGEXP_CONTAINS(LOWER(SPLIT(REGEXP_REPLACE(page_location,r'^https?://[^/]+/',''),'/')[OFFSET(3)]),
                                r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
             OR REGEXP_CONTAINS(LOWER(SPLIT(REGEXP_REPLACE(page_location,r'^https?://[^/]+/',''),'/')[OFFSET(4)]),
                                r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
           )
           AND REGEXP_CONTAINS(SPLIT(page_location,'/')[OFFSET(ARRAY_LENGTH(SPLIT(page_location,'/'))-1)], r'\+')
      THEN 'PDP'

      -- ------------ PLP ------------
      WHEN ARRAY_LENGTH(SPLIT(REGEXP_REPLACE(page_location,r'^https?://[^/]+/',''),'/')) >= 5
           AND (
                REGEXP_CONTAINS(LOWER(SPLIT(REGEXP_REPLACE(page_location,r'^https?://[^/]+/',''),'/')[OFFSET(3)]),
                                r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
             OR REGEXP_CONTAINS(LOWER(SPLIT(REGEXP_REPLACE(page_location,r'^https?://[^/]+/',''),'/')[OFFSET(4)]),
                                r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
           )
           AND NOT REGEXP_CONTAINS(SPLIT(page_location,'/')[OFFSET(ARRAY_LENGTH(SPLIT(page_location,'/'))-1)], r'\+')
      THEN 'PLP'

      -- ------------ Everything else keeps its title ------------
      ELSE page_title
    END AS step_label
  FROM pageviews
),

dedup AS (             -- 3. remove consecutive duplicates
  SELECT
    event_timestamp,
    step_label,
    LAG(step_label) OVER (ORDER BY event_timestamp) AS prev_label
  FROM classified
),

clean AS (
  SELECT event_timestamp, step_label
  FROM   dedup
  WHERE  prev_label IS NULL OR prev_label <> step_label
)

-- 4. build single navigation string joined by “ >> ”
SELECT STRING_AGG(step_label, ' >> ' ORDER BY event_timestamp) AS navigation_flow
FROM   clean;