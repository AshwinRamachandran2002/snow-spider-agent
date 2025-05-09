-- Navigation flow (page_view only) for user 1362228.4966015575 on 28‑Jan‑2021
WITH base_events AS (                -- 1. isolate the user’s page_view events for the day
  SELECT
    event_timestamp,
    -- pull the needed parameters out of the repeated event_params array
    MAX(CASE WHEN ep.key = 'page_location' THEN ep.value.string_value END) AS page_location,
    MAX(CASE WHEN ep.key = 'page_title'    THEN ep.value.string_value END) AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`,
       UNNEST(event_params) ep
  WHERE event_name         = 'page_view'
    AND event_date         = '20210128'
    AND user_pseudo_id     = '1362228.4966015575'
  GROUP BY event_timestamp
),
classified AS (                      -- 2. classify each row as PDP / PLP / other
  SELECT
    event_timestamp,
    page_title,
    page_location,
    -- ---------- URL parsing helpers ----------
    SPLIT(REGEXP_REPLACE(page_location, r'^https?://', ''), '/')                      AS segments,
    '(accessories|apparel|brands|campus|drinkware|electronics|google\\+redesign|' ||
    'lifestyle|nest|new\\+2015\\+logo|notebooks|journals|office|shop\\+by\\+brand|'  ||
    'small|stationery|wearables)'                                                     AS category_pattern
  FROM base_events
), labelled AS (
  SELECT
    event_timestamp,
    CASE
      -- ----- PDP -----
      WHEN seg_len >= 5
           AND (REGEXP_CONTAINS(LOWER(seg4), category_pattern)
                OR REGEXP_CONTAINS(LOWER(seg5), category_pattern))
           AND REGEXP_CONTAINS(last_seg, r'\+')
      THEN 'PDP'
      -- ----- PLP -----
      WHEN seg_len >= 5
           AND (REGEXP_CONTAINS(LOWER(seg4), category_pattern)
                OR REGEXP_CONTAINS(LOWER(seg5), category_pattern))
           AND NOT REGEXP_CONTAINS(seg4, r'\+')
           AND NOT REGEXP_CONTAINS(seg5, r'\+')
      THEN 'PLP'
      -- ----- everything else -----
      ELSE page_title
    END AS page_label
  FROM (
    SELECT
      event_timestamp,
      page_title,
      segments,
      ARRAY_LENGTH(segments)                       AS seg_len,
      segments[SAFE_OFFSET(3)]                     AS seg4,          -- 4‑th segment (0‑based)
      segments[SAFE_OFFSET(4)]                     AS seg5,          -- 5‑th segment
      segments[OFFSET(ARRAY_LENGTH(segments)-1)]   AS last_seg,
      category_pattern
    FROM classified
  )
),
deduped AS (                         -- 3. remove adjacent duplicates
  SELECT
    page_label,
    event_timestamp,
    LAG(page_label) OVER (ORDER BY event_timestamp) AS prev_label
  FROM labelled
)
SELECT
  STRING_AGG(page_label, ' >> ' ORDER BY event_timestamp) AS navigation_flow
FROM deduped
WHERE page_label IS NOT NULL
  AND (prev_label IS NULL OR page_label != prev_label);