WITH page_views AS (
  -- pull all page_view events of 2‑Jan‑2021 and get their URLs
  SELECT
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
       UNNEST(event_params) ep
  WHERE event_name = 'page_view'
    AND ep.key = 'page_location'
    AND ep.value.string_value IS NOT NULL
),
splitted AS (
  -- split each URL into path segments (remove protocol first)
  SELECT
    page_location,
    SPLIT(REGEXP_REPLACE(page_location, r'^https?://', ''), '/') AS segments
  FROM page_views
),
classified AS (
  -- pull out segment information we need for the PDP rules
  SELECT
    page_location,
    segments,
    ARRAY_LENGTH(segments)                                   AS seg_len,
    LOWER(segments[ORDINAL(ARRAY_LENGTH(segments))])         AS last_seg,
    LOWER(segments[OFFSET(3)])                               AS seg4,
    LOWER(segments[OFFSET(4)])                               AS seg5
  FROM splitted
),
flags AS (
  -- flag page views that qualify as PDPs
  SELECT
    *,
    seg_len >= 5
    AND REGEXP_CONTAINS(last_seg, r'\+')            -- “+” in last segment
    AND (
         REGEXP_CONTAINS(seg4, r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
      OR REGEXP_CONTAINS(seg5, r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
        )
    AS is_pdp
  FROM classified
),
stats AS (
  SELECT
    COUNT(*)            AS total_page_views,
    COUNTIF(is_pdp)     AS pdp_page_views
  FROM flags
)
SELECT
  ROUND(pdp_page_views / total_page_views * 100, 4) AS pdp_page_view_percentage
FROM stats;