-- Navigation flow (PLP / PDP / page titles) for user 1362228.4966015575 on 2021-01-28
WITH pageviews AS (
  -- 1️⃣ Pull the URL and title of every page_view
  SELECT
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location') AS page_location,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title')    AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE user_pseudo_id = '1362228.4966015575'
    AND event_name     = 'page_view'
),
classified AS (
  -- 2️⃣ Classify each row                             ────► PDP / PLP / fallback title
  SELECT
    event_timestamp,
    CASE
      -- PDP  : “+” in last segment + category keyword somewhere in path
      WHEN page_location IS NOT NULL
           AND REGEXP_CONTAINS(
                 LOWER(page_location),
                 r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/'
               )
           AND REGEXP_CONTAINS(page_location, r'/[^/]*\+[^/]*$')
        THEN 'PDP'

      -- PLP  : same category keyword but NO “+” in last segment
      WHEN page_location IS NOT NULL
           AND REGEXP_CONTAINS(
                 LOWER(page_location),
                 r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/'
               )
           AND NOT REGEXP_CONTAINS(page_location, r'/[^/]*\+[^/]*$')
        THEN 'PLP'

      -- Anything else → keep original page_title
      ELSE page_title
    END AS page_step
  FROM pageviews
)
-- 3️⃣ Remove consecutive duplicates, then join with “ >> ”
SELECT
  STRING_AGG(page_step, ' >> ' ORDER BY event_timestamp) AS navigation_flow
FROM (
  SELECT
    event_timestamp,
    page_step
  FROM classified
  QUALIFY page_step != LAG(page_step) OVER (ORDER BY event_timestamp)
);