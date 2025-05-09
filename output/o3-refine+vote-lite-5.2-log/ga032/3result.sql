WITH base AS (    -- 1. raw page_view hits for the user/day
  SELECT
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1) AS page_location,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title'
      LIMIT 1) AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE event_name     = 'page_view'
    AND user_pseudo_id = '1362228.4966015575'
),

classified AS (    -- 2. break URL into path segments
  SELECT
    event_timestamp,
    page_title,
    page_location,
    SPLIT( REGEXP_REPLACE(page_location, r'^https?://', ''), '/' ) AS segments
  FROM base
),

steps AS (         -- 3. add category‑regex (only once, avoiding duplicate columns)
  SELECT
    c.event_timestamp,
    c.page_title,
    c.page_location,
    c.segments,
    r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)' AS cat_re
  FROM classified c
),

tagged AS (        -- 4. label each hit as PDP / PLP / original title
  SELECT
    event_timestamp,
    CASE
      /* -------- PDP -------- */
      WHEN ARRAY_LENGTH(segments) >= 5
           AND (
                REGEXP_CONTAINS(LOWER(segments[SAFE_OFFSET(3)]), cat_re)
             OR REGEXP_CONTAINS(LOWER(segments[SAFE_OFFSET(4)]), cat_re)
               )
           AND REGEXP_CONTAINS(segments[ORDINAL(ARRAY_LENGTH(segments))], r'\+')
        THEN 'PDP'

      /* -------- PLP -------- */
      WHEN ARRAY_LENGTH(segments) >= 5
           AND (
                REGEXP_CONTAINS(LOWER(segments[SAFE_OFFSET(3)]), cat_re)
             OR REGEXP_CONTAINS(LOWER(segments[SAFE_OFFSET(4)]), cat_re)
               )
           AND NOT REGEXP_CONTAINS(IFNULL(segments[SAFE_OFFSET(3)], ''), r'\+')
           AND NOT REGEXP_CONTAINS(IFNULL(segments[SAFE_OFFSET(4)], ''), r'\+')
        THEN 'PLP'

      /* -------- Anything else -------- */
      ELSE page_title
    END AS step
  FROM steps
),

dedup AS (         -- 5. remove consecutive duplicates
  SELECT
    step,
    event_timestamp,
    LAG(step) OVER (ORDER BY event_timestamp) AS prev_step
  FROM tagged
)

-- 6. build the navigation flow string
SELECT
  STRING_AGG(step, '>>' ORDER BY event_timestamp) AS navigation_flow
FROM dedup
WHERE step IS NOT NULL
  AND (prev_step IS NULL OR step <> prev_step);