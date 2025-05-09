-- pages visited by the required user on 2021‑01‑02, with PDP / PLP labelling
WITH
-- 1. list of category keywords (lower‑cased, spaces kept)
categories AS (
  SELECT [
    'accessories','apparel','brands','campus collection','drinkware','electronics',
    'google redesign','lifestyle','nest','new 2015 logo','notebooks journals',
    'office','shop by brand','small goods','stationery','wearables'
  ] AS list
),

-- 2. extract page_title and page_location from the page_view events
base AS (
  SELECT
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'page_title')    AS page_title,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE user_pseudo_id = '1402138.5184246691'
    AND event_name   = 'page_view'
),

-- 3. split URL to path segments
parsed AS (
  SELECT
    b.*,
    -- take everything after the host and split by “/”
    SPLIT(
      REGEXP_EXTRACT(page_location, r'^https?://[^/]+/(.*)$'), '/'
    ) AS segments,
    c.list AS categories
  FROM base b
  CROSS JOIN categories c
),

-- 4. pick the segments of interest
classified AS (
  SELECT
    page_title,
    page_location,
    segments,
    segments[SAFE_OFFSET(3)]                        AS segment4,
    segments[SAFE_OFFSET(4)]                        AS segment5,
    segments[SAFE_OFFSET(ARRAY_LENGTH(segments)-1)] AS last_segment,
    categories
  FROM parsed
)

-- 5. return distinct page names, converted to PDP / PLP when rules match
SELECT DISTINCT
  CASE
    /* PDP: ≥5 segments, last one contains “+”, 4th or 5th segment is a category */
    WHEN ARRAY_LENGTH(segments) >= 5
         AND last_segment LIKE '%+%'
         AND (LOWER(segment4) IN UNNEST(categories)
              OR LOWER(segment5) IN UNNEST(categories))
      THEN 'PDP'

    /* PLP: ≥5 segments, 4th & 5th do NOT contain “+”, but one of them is a category */
    WHEN ARRAY_LENGTH(segments) >= 5
         AND NOT (segment4 LIKE '%+%' OR segment5 LIKE '%+%')
         AND (LOWER(segment4) IN UNNEST(categories)
              OR LOWER(segment5) IN UNNEST(categories))
      THEN 'PLP'

    /* otherwise keep the original page title */
    ELSE page_title
  END AS page_name
FROM classified
ORDER BY page_name;