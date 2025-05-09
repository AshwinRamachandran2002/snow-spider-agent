/*  PLP → PDP transition rate on 2‑Jan‑2021  */
WITH page_views AS (               -- keep only 2‑Jan‑2021 page_view hits
  SELECT
    user_pseudo_id,
    ( SELECT value.int_value          -- GA4 session id
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id')    AS session_id,
    event_timestamp,
    ( SELECT value.string_value       -- full URL
      FROM UNNEST(event_params)
      WHERE key = 'page_location')    AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
parsed AS (                         -- split URL into path segments
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    page_location,
    SPLIT( REGEXP_EXTRACT(page_location, r'^https?://[^/]+/(.*)$') , '/' ) AS segments
  FROM page_views
  WHERE page_location IS NOT NULL
),
classified AS (                     -- prepare helper columns
  SELECT
    *,
    ARRAY_LENGTH(segments)                            AS seg_len,
    segments[SAFE_OFFSET(3)]                          AS seg4,
    segments[SAFE_OFFSET(4)]                          AS seg5,
    segments[OFFSET(ARRAY_LENGTH(segments) - 1)]      AS last_seg
  FROM parsed
),
flagged AS (                        -- tag each hit as PLP / PDP
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    page_location,
    /* Product‑listing page (PLP) */
    CASE
      WHEN seg_len >= 5
       AND ( REGEXP_CONTAINS(LOWER(seg4), r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
          OR REGEXP_CONTAINS(LOWER(seg5), r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
       ) AND NOT REGEXP_CONTAINS(seg4, r'\+')
         AND NOT REGEXP_CONTAINS(seg5, r'\+')
      THEN TRUE ELSE FALSE
    END                                               AS is_plp,

    /* Product‑detail page (PDP) */
    CASE
      WHEN seg_len >= 5
       AND ( REGEXP_CONTAINS(LOWER(seg4), r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
          OR REGEXP_CONTAINS(LOWER(seg5), r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
       ) AND REGEXP_CONTAINS(last_seg, r'\+')
      THEN TRUE ELSE FALSE
    END                                               AS is_pdp
  FROM classified
),
plp_events AS (                      -- every PLP view
  SELECT *
  FROM flagged
  WHERE is_plp = TRUE
    AND session_id IS NOT NULL
),
pdp_events AS (                      -- every PDP view
  SELECT *
  FROM flagged
  WHERE is_pdp = TRUE
    AND session_id IS NOT NULL
),
/* PLP views that are followed by a PDP in the SAME session */
plp_leading_to_pdp AS (
  SELECT DISTINCT p.*
  FROM plp_events  AS p
  JOIN pdp_events  AS d
    ON  p.user_pseudo_id = d.user_pseudo_id
   AND p.session_id     = d.session_id
   AND d.event_timestamp > p.event_timestamp          -- happens later
)
SELECT
  (SELECT COUNT(*) FROM plp_events)          AS total_plp_views,
  (SELECT COUNT(*) FROM plp_leading_to_pdp)  AS plp_views_leading_to_pdp,
  ROUND(100 * (SELECT COUNT(*) FROM plp_leading_to_pdp)
/           NULLIF((SELECT COUNT(*) FROM plp_events),0), 4)
                                             AS plp_to_pdp_percentage
;