-- pages visited by user 1402138.5184246691 on 2‑Jan‑2021
WITH raw AS (      -- pull the title & URL of every hit for the user on the day
  SELECT
    ( SELECT ep.value.string_value
      FROM   UNNEST(event_params) AS ep
      WHERE  ep.key = 'page_title'
      LIMIT  1 )                                            AS page_title,

    ( SELECT ep.value.string_value
      FROM   UNNEST(event_params) AS ep
      WHERE  ep.key = 'page_location'
      LIMIT  1 )                                            AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_date     = '20210102'
    AND user_pseudo_id = '1402138.5184246691'
),
parsed AS (        -- split the URL into path segments
  SELECT
    page_title,
    page_location,
    SPLIT( REGEXP_REPLACE(page_location , r'^https?://[^/]+/' , ''), '/' ) AS segments
  FROM raw
  WHERE page_location IS NOT NULL
),
classified AS (    -- decide whether the URL is a PDP or PLP
  SELECT
    page_title,
    page_location,
    CASE
      WHEN ARRAY_LENGTH(segments) >= 5
           AND ( REGEXP_CONTAINS( LOWER(segments[OFFSET(3)] ),
                                  r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)' )
              OR REGEXP_CONTAINS( LOWER(segments[OFFSET(4)] ),
                                  r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)' ) )
           AND REGEXP_CONTAINS( ARRAY_REVERSE(segments)[OFFSET(0)] , r'\+' )
        THEN 'PDP'

      WHEN ARRAY_LENGTH(segments) >= 5
           AND ( REGEXP_CONTAINS( LOWER(segments[OFFSET(3)] ),
                                  r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)' )
              OR REGEXP_CONTAINS( LOWER(segments[OFFSET(4)] ),
                                  r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)' ) )
           AND NOT REGEXP_CONTAINS( segments[OFFSET(3)] , r'\+' )
           AND NOT REGEXP_CONTAINS( segments[OFFSET(4)] , r'\+' )
        THEN 'PLP'
      ELSE NULL
    END AS page_type
  FROM parsed
)
SELECT DISTINCT
  COALESCE(page_type, page_title, page_location) AS page_name
FROM classified
ORDER BY page_name;