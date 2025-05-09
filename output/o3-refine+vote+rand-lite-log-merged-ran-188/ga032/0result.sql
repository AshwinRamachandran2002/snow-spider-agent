WITH base AS (
  -- 1. pull all page_view hits for the user and extract helpers
  SELECT
    event_timestamp,
    ( SELECT ep.value.string_value
      FROM   UNNEST(event_params) AS ep
      WHERE  ep.key = 'page_title'
      LIMIT 1 )                                         AS page_title,
    ( SELECT ep.value.string_value
      FROM   UNNEST(event_params) AS ep
      WHERE  ep.key = 'page_location'
      LIMIT 1 )                                         AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE user_pseudo_id = '1362228.4966015575'
    AND event_name     = 'page_view'
),
labeled AS (
  -- 2. turn each hit into PDP / PLP / page_title
  SELECT
    event_timestamp,
    CASE
      /* PDP  = one of the known categories AND a “+” in the last segment */
      WHEN REGEXP_CONTAINS(
             LOWER(page_location),
             r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/[^/]*\+'
           )
           THEN 'PDP'

      /* PLP  = in a category path but no “+” in the 4th/5th segment       */
      WHEN REGEXP_CONTAINS(
             LOWER(page_location),
             r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/'
           )
           THEN 'PLP'

      /* everything else keeps its page_title                               */
      ELSE page_title
    END AS page_label
  FROM base
),
dedup AS (
  -- 3. drop consecutive duplicates
  SELECT
    event_timestamp,
    page_label
  FROM labeled
  WHERE page_label IS NOT NULL
  QUALIFY page_label <> LAG(page_label) OVER (ORDER BY event_timestamp)
         OR LAG(page_label) OVER (ORDER BY event_timestamp) IS NULL
)

-- 4. stitch the journey together
SELECT STRING_AGG(page_label, ' >> ' ORDER BY event_timestamp) AS navigation_flow
FROM   dedup;