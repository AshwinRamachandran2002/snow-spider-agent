-- PLP‑to‑PDP transition rate for 2‑Jan‑2021
WITH base AS (   -- pull only 2‑Jan‑2021 page_view events and the fields we need
  SELECT
    user_pseudo_id,
    /* session identifier */
    (SELECT ep.value.int_value
     FROM   UNNEST(event_params) ep
     WHERE  ep.key = 'ga_session_id')              AS session_id,
    event_timestamp,
    LOWER(          -- normalise the URL
      (SELECT ep.value.string_value
       FROM   UNNEST(event_params) ep
       WHERE  ep.key = 'page_location')
    )                                               AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
segments AS (     -- split the URL into path segments
  SELECT
    *,
    SPLIT( REGEXP_EXTRACT(url, r'^https?://[^/]+/(.*)$'), '/') AS segs
  FROM base
),
classified AS (   -- label each page_view as PLP / PDP (or ignore)
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    url,
    /* the 4th & 5th path segments (index starts at 0) */
    segs[OFFSET(3)] AS seg4,
    segs[OFFSET(4)] AS seg5,
    ARRAY_LENGTH(segs) AS seg_cnt,
    segs,
    CASE
      /* ---------- Product‑Listing Page (PLP) ---------- */
      WHEN ARRAY_LENGTH(segs) >= 5
           AND NOT REGEXP_CONTAINS(segs[OFFSET(3)], r'\+')
           AND NOT REGEXP_CONTAINS(segs[OFFSET(4)], r'\+')
           AND ( REGEXP_CONTAINS(segs[OFFSET(3)], r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
              OR REGEXP_CONTAINS(segs[OFFSET(4)], r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
           )
        THEN 'PLP'

      /* ---------- Product‑Detail Page (PDP) ---------- */
      WHEN ARRAY_LENGTH(segs) >= 5
           AND REGEXP_CONTAINS( segs[OFFSET(ARRAY_LENGTH(segs)-1)], r'\+' )
           AND ( REGEXP_CONTAINS(segs[OFFSET(3)], r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
              OR REGEXP_CONTAINS(segs[OFFSET(4)], r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
           )
        THEN 'PDP'
    END AS page_type
  FROM segments
),
plp AS ( SELECT * FROM classified WHERE page_type = 'PLP' ),
pdp AS ( SELECT * FROM classified WHERE page_type = 'PDP' ),

/* --------------- PLPs that eventually lead to a PDP inside the same session --------------- */
plp_that_lead_to_pdp AS (
  SELECT DISTINCT plp.user_pseudo_id,
                  plp.session_id,
                  plp.event_timestamp
  FROM plp
  JOIN pdp
    ON  plp.user_pseudo_id = pdp.user_pseudo_id
    AND plp.session_id     = pdp.session_id
    AND pdp.event_timestamp > plp.event_timestamp   -- PDP happens after the PLP
)

SELECT
  COUNT(*)                                   AS total_plp_views,
  (SELECT COUNT(*) FROM plp_that_lead_to_pdp) AS plp_views_leading_to_pdp,
  ROUND( SAFE_DIVIDE(
           (SELECT COUNT(*) FROM plp_that_lead_to_pdp),
           COUNT(*) ) * 100 , 4)             AS plp_to_pdp_percentage
FROM plp;