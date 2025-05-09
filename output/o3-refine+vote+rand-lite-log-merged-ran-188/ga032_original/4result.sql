WITH categories AS (  -- category names exactly as they appear in URLs (lower‑case, blanks → '+')
  SELECT *
  FROM UNNEST([
    'accessories','apparel','brands','campus+collection','drinkware','electronics',
    'google+redesign','lifestyle','nest','new+2015+logo','notebooks+journals',
    'office','shop+by+brand','small+goods','stationery','wearables'
  ]) AS category
),
user_pageviews AS (            -- 1. all page_view hits for the user on 28‑Jan‑2021
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
  WHERE user_pseudo_id = '1362228.4966015575'
    AND event_name     = 'page_view'
),
prepared AS (                 -- 2. split URL → segments & helper columns
  SELECT
    event_timestamp,
    page_title,
    page_location,
    segments,
    ARRAY_LENGTH(segments)                                   AS seg_len,
    LOWER(IFNULL(segments[SAFE_OFFSET(3)], ''))              AS seg4,
    LOWER(IFNULL(segments[SAFE_OFFSET(4)], ''))              AS seg5,
    REGEXP_CONTAINS(IFNULL(segments[SAFE_OFFSET(ARRAY_LENGTH(segments)-1)], ''), r'\+') AS last_seg_plus,
    REGEXP_CONTAINS(IFNULL(segments[SAFE_OFFSET(3)], ''), r'\+')                           AS seg4_plus,
    REGEXP_CONTAINS(IFNULL(segments[SAFE_OFFSET(4)], ''), r'\+')                           AS seg5_plus
  FROM (
    SELECT
      event_timestamp,
      page_title,
      page_location,
      SPLIT( COALESCE(REGEXP_EXTRACT(page_location, r'https?://[^/]+/(.*)'), ''), '/' ) AS segments
    FROM user_pageviews
  )
),
classified AS (             -- 3. label each hit as PDP / PLP / other page_title
  SELECT
    event_timestamp,
    CASE
      WHEN seg_len >= 5
           AND (seg4 IN (SELECT category FROM categories)
                OR seg5 IN (SELECT category FROM categories))
           AND last_seg_plus
        THEN 'PDP'
      WHEN seg_len >= 5
           AND (seg4 IN (SELECT category FROM categories)
                OR seg5 IN (SELECT category FROM categories))
           AND NOT seg4_plus
           AND NOT seg5_plus
           AND NOT last_seg_plus
        THEN 'PLP'
      ELSE COALESCE(page_title, 'Unknown')
    END AS page_label
  FROM prepared
),
dedup AS (                 -- 4. collapse consecutive duplicates
  SELECT
    event_timestamp,
    page_label,
    LAG(page_label) OVER (ORDER BY event_timestamp) AS prev_label
  FROM classified
),
cleaned AS (
  SELECT event_timestamp, page_label
  FROM dedup
  WHERE prev_label IS NULL OR page_label <> prev_label
)
-- 5. build the navigation flow string
SELECT STRING_AGG(page_label, '>>' ORDER BY event_timestamp) AS navigation_flow
FROM   cleaned;