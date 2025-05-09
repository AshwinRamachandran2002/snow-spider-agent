/*  PLP → PDP transition rate for 2021-01-02  */
WITH pageviews AS (          -- pull all page_view rows + key fields
  SELECT
    event_timestamp,
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id')                               AS ga_session_id,
    LOWER(
      (SELECT ep.value.string_value
         FROM UNNEST(event_params) ep
         WHERE ep.key = 'page_location'))                            AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
url_parts AS (                -- isolate the path & split into segments
  SELECT
    *,
    SPLIT(REGEXP_EXTRACT(url, r'https?://[^/]+/(.*)'), '/') AS segs
  FROM pageviews
),
classified AS (               -- label each view as PLP / PDP / OTHER
  SELECT
    *,
    CASE
      /* -------- PLP -------- */
      WHEN ARRAY_LENGTH(segs) >= 5
           AND ( REGEXP_CONTAINS(segs[OFFSET(3)],
                  r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
              OR REGEXP_CONTAINS(segs[SAFE_OFFSET(4)],
                  r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'))
           AND NOT REGEXP_CONTAINS(segs[OFFSET(3)], r'\+')
           AND NOT REGEXP_CONTAINS(segs[SAFE_OFFSET(4)], r'\+')
        THEN 'PLP'

      /* -------- PDP -------- */
      WHEN ARRAY_LENGTH(segs) >= 5
           AND ( REGEXP_CONTAINS(segs[OFFSET(3)],
                  r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
              OR REGEXP_CONTAINS(segs[SAFE_OFFSET(4)],
                  r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'))
           AND REGEXP_CONTAINS(segs[ORDINAL(ARRAY_LENGTH(segs))], r'\+')
        THEN 'PDP'

      ELSE 'OTHER'
    END AS page_type
  FROM url_parts
),
plp_views AS (SELECT * FROM classified WHERE page_type = 'PLP'),
pdp_views AS (SELECT * FROM classified WHERE page_type = 'PDP'),

/* does a given PLP have a later PDP in the same session? */
plp_flagged AS (
  SELECT
    p.*,
    EXISTS (
      SELECT 1
      FROM   pdp_views d
      WHERE  d.user_pseudo_id = p.user_pseudo_id
        AND  d.ga_session_id  = p.ga_session_id
        AND  d.event_timestamp > p.event_timestamp
    ) AS led_to_pdp
  FROM plp_views p
)

SELECT
  COUNT(*)                              AS total_plp_views,
  COUNTIF(led_to_pdp)                   AS plp_that_lead_to_pdp,
  SAFE_DIVIDE(COUNTIF(led_to_pdp), COUNT(*)) AS pct_plp_to_pdp
FROM plp_flagged;