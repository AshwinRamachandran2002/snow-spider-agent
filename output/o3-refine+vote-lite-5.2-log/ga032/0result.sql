WITH base AS (
  -- pull all page_view events for the user on 28‑Jan‑2021
  SELECT
    event_timestamp,
    -- extract URL and title from the repeated event_params record
    ( SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1 )                                              AS page_location ,
    ( SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title'
      LIMIT 1 )                                              AS page_title
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE event_name     = 'page_view'
    AND user_pseudo_id = '1362228.4966015575'
),
classified AS (
  -- identify PLP / PDP, otherwise keep the page title
  SELECT
    event_timestamp ,
    page_location ,
    page_title ,
    CASE
      -- ---------- PDP test ----------
      WHEN page_location IS NOT NULL
           AND (
                 /* number of path segments ≥ 5 */
                 ARRAY_LENGTH(SPLIT( REGEXP_EXTRACT(page_location , r'https?://[^/]+/(.*)') , '/' )) >= 5
               )
           AND (
                 -- 4th OR 5th segment contains a recognised category word
                 REGEXP_CONTAINS( LOWER( IFNULL( SPLIT( REGEXP_EXTRACT(page_location , r'https?://[^/]+/(.*)') , '/')[OFFSET(3)] , '') )
                                  , r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)' )
              OR REGEXP_CONTAINS( LOWER( IFNULL( SPLIT( REGEXP_EXTRACT(page_location , r'https?://[^/]+/(.*)') , '/')[OFFSET(4)] , '') )
                                  , r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)' )
               )
           /* last segment contains a '+' sign  → PDP */
           AND REGEXP_CONTAINS( LOWER( ARRAY_REVERSE( SPLIT( REGEXP_EXTRACT(page_location , r'https?://[^/]+/(.*)') , '/') )[OFFSET(0)] ) , r'\+' )
        THEN 'PDP'

      -- ---------- PLP test ----------
      WHEN page_location IS NOT NULL
           AND (
                 ARRAY_LENGTH(SPLIT( REGEXP_EXTRACT(page_location , r'https?://[^/]+/(.*)') , '/' )) >= 5
               )
           AND (
                 REGEXP_CONTAINS( LOWER( IFNULL( SPLIT( REGEXP_EXTRACT(page_location , r'https?://[^/]+/(.*)') , '/')[OFFSET(3)] , '') )
                                  , r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)' )
              OR REGEXP_CONTAINS( LOWER( IFNULL( SPLIT( REGEXP_EXTRACT(page_location , r'https?://[^/]+/(.*)') , '/')[OFFSET(4)] , '') )
                                  , r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)' )
               )
           /* neither 4th nor 5th segment contains '+'  → PLP */
           AND NOT REGEXP_CONTAINS( LOWER( IFNULL( SPLIT( REGEXP_EXTRACT(page_location , r'https?://[^/]+/(.*)') , '/')[OFFSET(3)] , '') ) , r'\+' )
           AND NOT REGEXP_CONTAINS( LOWER( IFNULL( SPLIT( REGEXP_EXTRACT(page_location , r'https?://[^/]+/(.*)') , '/')[OFFSET(4)] , '') ) , r'\+' )
        THEN 'PLP'

      /* anything else keeps its original (possibly NULL) title */
      ELSE page_title
    END AS page_label
  FROM base
),
dedup AS (
  -- drop successive duplicates so the same page doesn’t repeat
  SELECT
    event_timestamp,
    page_label
  FROM classified
  WHERE page_label IS NOT NULL
  QUALIFY page_label != LAG(page_label) OVER (ORDER BY event_timestamp)
          OR LAG(page_label) OVER (ORDER BY event_timestamp) IS NULL
)
SELECT
  STRING_AGG(page_label, '>>' ORDER BY event_timestamp) AS navigation_flow
FROM dedup;