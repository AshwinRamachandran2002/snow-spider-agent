WITH base AS (
  SELECT
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title')            AS page_title,
    LOWER((SELECT ep.value.string_value
             FROM UNNEST(event_params) ep
            WHERE ep.key = 'page_location')) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE user_pseudo_id = '1362228.4966015575'
    AND event_name     = 'page_view'
),
classified AS (
  SELECT
    event_timestamp,
    CASE
      WHEN page_location IS NULL THEN page_title
      WHEN ARRAY_LENGTH(SPLIT(page_location, '/')) >= 5
           AND REGEXP_CONTAINS(page_location, r'/[^/]*\+')
           AND REGEXP_CONTAINS(page_location,
                 r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
           THEN 'PDP'
      WHEN ARRAY_LENGTH(SPLIT(page_location, '/')) >= 5
           AND NOT REGEXP_CONTAINS(page_location, r'/[^/]*\+')
           AND REGEXP_CONTAINS(page_location,
                 r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
           THEN 'PLP'
      ELSE page_title
    END AS step
  FROM base
),
ordered AS (
  SELECT
    step,
    ROW_NUMBER() OVER (ORDER BY event_timestamp) AS rn
  FROM classified
),
dedup AS (
  SELECT
    step,
    rn
  FROM ordered o
  WHERE NOT EXISTS (
        SELECT 1
        FROM ordered p
        WHERE p.rn = o.rn - 1
          AND p.step = o.step)
)
SELECT STRING_AGG(step, '>>' ORDER BY rn) AS navigation_flow
FROM dedup;