-- Navigation flow (de-duplicated, PDP / PLP collapsed)  
-- for user 1362228.4966015575 on 28-Jan-2021
WITH base AS (         -- pull raw title / URL for every page_view
  SELECT
    event_timestamp,
    (SELECT value.string_value
       FROM UNNEST(event_params)
      WHERE key = 'page_title')    AS page_title,
    (SELECT value.string_value
       FROM UNNEST(event_params)
      WHERE key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE user_pseudo_id = '1362228.4966015575'
    AND event_name     = 'page_view'
),
classified AS (        -- label each hit as PDP / PLP / OTHER
  SELECT
    event_timestamp,
    page_title,
    CASE
      /* PDP = catalogue word + “+” in final segment */
      WHEN REGEXP_CONTAINS(
             LOWER(page_location),
             r'^https?://[^/]+(?:/[^/]+){3,4}/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/[^/]*\+'
           )
      THEN 'PDP'

      /* PLP = catalogue word but NO “+” in final segment */
      WHEN REGEXP_CONTAINS(
             LOWER(page_location),
             r'^https?://[^/]+(?:/[^/]+){3,4}/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/[^/+]*$'
           )
      THEN 'PLP'

      ELSE 'OTHER'
    END AS page_type
  FROM base
),
typed AS (             -- collapse PDP / PLP rows to their shorthand
  SELECT
    event_timestamp,
    CASE WHEN page_type IN ('PDP','PLP') THEN page_type ELSE page_title END AS page_name
  FROM classified
),
dedup AS (             -- remove consecutive repeats
  SELECT *
  FROM (
    SELECT
      event_timestamp,
      page_name,
      LAG(page_name) OVER (ORDER BY event_timestamp) AS prev_page
    FROM typed
  )
  WHERE prev_page IS NULL OR prev_page <> page_name
)
SELECT
  STRING_AGG(page_name, ' >> ' ORDER BY event_timestamp) AS navigation_flow
FROM dedup;