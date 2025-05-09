-- Navigation flow for user 1362228.4966015575 on 2021‑01‑28 (page_view events only)
WITH page_views AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    -- extract needed parameters
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'page_title')     AS page_title,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'page_location')  AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE event_date       = '20210128'
    AND user_pseudo_id   = '1362228.4966015575'
    AND event_name       = 'page_view'
),

classified AS (
  SELECT
    event_timestamp,
    -- classify each page into PDP / PLP (else keep original title)
    CASE
      -- PDP  ▸  at least 5 path segments, last segment has '+', and path contains a category name
      WHEN REGEXP_CONTAINS(page_location,
             r'^https?://[^/]+/(?:[^/]+/){4,}[^/]*\+')
       AND REGEXP_CONTAINS(LOWER(page_location),
             r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/')
      THEN 'PDP'

      -- PLP  ▸  at least 5 segments, contains category name, but NO ‘+’ in 4th or 5th segment
      WHEN REGEXP_CONTAINS(page_location,
             r'^https?://[^/]+/(?:[^/]+/){4,}[^/]*$')
       AND REGEXP_CONTAINS(LOWER(page_location),
             r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/')
       AND NOT REGEXP_CONTAINS(page_location, r'\+')
      THEN 'PLP'

      -- anything else keeps its page_title
      ELSE page_title
    END AS page_step
  FROM page_views
),

-- drop consecutive duplicates
deduplicated AS (
  SELECT
    page_step,
    event_timestamp,
    LAG(page_step) OVER (ORDER BY event_timestamp) AS prev_step
  FROM classified
),

filtered AS (
  SELECT
    page_step,
    event_timestamp
  FROM deduplicated
  WHERE prev_step IS NULL OR page_step <> prev_step
  ORDER BY event_timestamp
)

-- build the navigation flow string
SELECT
  STRING_AGG(page_step, ' >> ' ORDER BY event_timestamp) AS navigation_flow
FROM filtered;