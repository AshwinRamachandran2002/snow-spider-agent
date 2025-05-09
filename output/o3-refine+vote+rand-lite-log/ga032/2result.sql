/* -----------------------------------------------------------
   Navigation flow for user 1362228.4966015575 on 28‑Jan‑2021
   – show only page_view events
   – convert URLs to PLP / PDP labels where rules match
   – merge adjacent identical pages
------------------------------------------------------------*/
WITH
-- recognised category words (lower‑case, spaces kept)
categories AS (
  SELECT [
    'accessories','apparel','brands','campus collection','drinkware','electronics',
    'google redesign','lifestyle','nest','new 2015 logo','notebooks journals',
    'office','shop by brand','small goods','stationery','wearables'
  ] AS cat
),

/* 1. All page_view events for the user/day with title & URL --------------- */
page_events AS (
  SELECT
    e.event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(e.event_params) ep
      WHERE ep.key = 'page_title')    AS page_title,
    (SELECT ep.value.string_value
       FROM UNNEST(e.event_params) ep
      WHERE ep.key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
  WHERE _TABLE_SUFFIX    = '20210128'              -- 28‑Jan‑2021
    AND e.event_name     = 'page_view'
    AND e.user_pseudo_id = '1362228.4966015575'
),

/* 2. Safely split the URL into segments ----------------------------------- */
url_parts AS (
  SELECT
    pe.*,
    SPLIT(COALESCE(pe.page_location, ''), '/') AS tokens
  FROM page_events pe
),

exploded AS (
  SELECT
    event_timestamp,
    page_title,
    page_location,
    ARRAY_LENGTH(tokens)                         AS seg_len,
    tokens[SAFE_OFFSET(3)]                       AS seg4_raw,
    tokens[SAFE_OFFSET(4)]                       AS seg5_raw,
    tokens[SAFE_OFFSET(ARRAY_LENGTH(tokens)-1)]  AS last_seg
  FROM url_parts
),

/* 3. Classify each hit as PDP / PLP / keep original title ------------------ */
classified AS (
  SELECT
    e.event_timestamp,
    CASE
      /* ---------- PDP ---------- */
      WHEN seg_len >= 5
           AND (norm_seg4 IN UNNEST(cat) OR norm_seg5 IN UNNEST(cat))
           AND last_seg LIKE '%+%'                                      THEN 'PDP'

      /* ---------- PLP ---------- */
      WHEN seg_len >= 5
           AND (norm_seg4 IN UNNEST(cat) OR norm_seg5 IN UNNEST(cat))
           AND (COALESCE(seg4_raw,'') NOT LIKE '%+%'
                AND COALESCE(seg5_raw,'') NOT LIKE '%+%')               THEN 'PLP'

      /* ---------- everything else: use title (fallback URL/UNKNOWN) ---- */
      ELSE COALESCE(e.page_title, e.page_location, 'UNKNOWN')
    END AS page_label
  FROM (
    SELECT
      ex.*,
      TRIM(LOWER(REPLACE(IFNULL(seg4_raw, ''), '+', ' '))) AS norm_seg4,
      TRIM(LOWER(REPLACE(IFNULL(seg5_raw, ''), '+', ' '))) AS norm_seg5
    FROM exploded ex
  ) e
  CROSS JOIN categories
),

/* 4. Remove consecutive duplicates to build clean path -------------------- */
deduped AS (
  SELECT
    event_timestamp,
    page_label,
    LAG(page_label) OVER (ORDER BY event_timestamp) AS prev_label
  FROM classified
),

final_steps AS (
  SELECT
    event_timestamp,
    page_label
  FROM deduped
  WHERE prev_label IS NULL OR page_label <> prev_label
  ORDER BY event_timestamp
)

/* 5. Assemble navigation string ------------------------------------------ */
SELECT
  STRING_AGG(page_label, '>>' ORDER BY event_timestamp) AS navigation_flow
FROM final_steps;