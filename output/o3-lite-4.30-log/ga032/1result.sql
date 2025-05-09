WITH base AS (
  SELECT
    event_timestamp,
    (SELECT value.string_value
       FROM UNNEST(event_params)
       WHERE key = 'page_title'
       LIMIT 1)                                            AS title,
    (SELECT value.string_value
       FROM UNNEST(event_params)
       WHERE key = 'page_location'
       LIMIT 1)                                            AS loc
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE event_date     = '20210128'
    AND user_pseudo_id = '1362228.4966015575'
    AND event_name     = 'page_view'
),
labeled AS (
  SELECT
    event_timestamp,
    CASE
      -- Product Detail Page
      WHEN ARRAY_LENGTH(path) >= 5
           AND STRPOS(path[SAFE_OFFSET(ARRAY_LENGTH(path)-1)], '+') > 0
           AND (
                 REGEXP_CONTAINS(REPLACE(path[SAFE_OFFSET(3)], '+', ' '), pattern) OR
                 REGEXP_CONTAINS(REPLACE(path[SAFE_OFFSET(4)], '+', ' '), pattern)
               )
        THEN 'PDP'
      -- Product Listing Page
      WHEN ARRAY_LENGTH(path) >= 5
           AND STRPOS(path[SAFE_OFFSET(ARRAY_LENGTH(path)-1)], '+') = 0
           AND (
                 REGEXP_CONTAINS(REPLACE(path[SAFE_OFFSET(3)], '+', ' '), pattern) OR
                 REGEXP_CONTAINS(REPLACE(path[SAFE_OFFSET(4)], '+', ' '), pattern)
               )
        THEN 'PLP'
      -- All other pages keep their original title
      ELSE title
    END AS page_type_or_title
  FROM (
    SELECT
      event_timestamp,
      title,
      SPLIT(LOWER(loc), '/') AS path,
      r'(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)' AS pattern
    FROM base
  )
),
dedup AS (
  SELECT
    event_timestamp,
    page_type_or_title,
    LAG(page_type_or_title) OVER (ORDER BY event_timestamp) AS prev_page
  FROM labeled
)
SELECT
  STRING_AGG(page_type_or_title, '>>' ORDER BY event_timestamp) AS navigation_flow
FROM dedup
WHERE prev_page IS NULL
   OR page_type_or_title <> prev_page;