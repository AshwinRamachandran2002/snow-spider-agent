WITH raw AS (
  -- 1. collect all page_view events for the user on 28‑Jan‑2021
  SELECT
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title'
      LIMIT 1)                          AS page_title,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1)                          AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE user_pseudo_id = '1362228.4966015575'
    AND event_name   = 'page_view'
),
classified AS (
  -- 2. turn each hit into PDP / PLP / page_title
  SELECT
    event_timestamp,
    page_title,
    page_location,
    CASE
      WHEN page_location IS NOT NULL
           AND ARRAY_LENGTH(SPLIT(page_location,'/')) >= 5
           AND (
                REGEXP_CONTAINS(
                    LOWER(SPLIT(page_location,'/')[OFFSET(3)]),
                    r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
                )
             OR REGEXP_CONTAINS(
                    LOWER(SPLIT(page_location,'/')[OFFSET(4)]),
                    r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
                )
           )
        THEN CASE
               WHEN REGEXP_CONTAINS(
                      SPLIT(page_location,'/')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(page_location,'/'))-1)],
                      r'\+'
                    )
               THEN 'PDP'
               ELSE 'PLP'
             END
        ELSE COALESCE(page_title,'UNKNOWN')
    END AS page_name
  FROM raw
),
dedup AS (
  -- 3. mark the first occurrence of consecutive identical pages
  SELECT
    *,
    CASE
      WHEN LAG(page_name) OVER (ORDER BY event_timestamp) = page_name
           THEN 0 ELSE 1
    END AS new_flag
  FROM classified
),
grp_steps AS (
  -- 4. build a running group id to collapse repeats
  SELECT
    *,
    SUM(new_flag) OVER (ORDER BY event_timestamp) AS grp
  FROM dedup
),
collapsed AS (
  -- 5. one row per step after collapsing consecutive duplicates
  SELECT
    grp,
    MIN(event_timestamp)           AS step_time,
    ANY_VALUE(page_name)           AS page_name
  FROM grp_steps
  GROUP BY grp
)
-- 6. stitch the journey together
SELECT
  STRING_AGG(page_name, ' >> ' ORDER BY step_time) AS navigation_flow
FROM collapsed;