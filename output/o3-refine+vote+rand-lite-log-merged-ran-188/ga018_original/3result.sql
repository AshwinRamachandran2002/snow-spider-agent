WITH page_views AS (
  -- pull every 2‑Jan‑2021 page_view with its url and session id
  SELECT
    event_timestamp,
    user_pseudo_id,
    COALESCE(
      (SELECT value.int_value   FROM UNNEST(event_params) WHERE key = 'ga_session_id'),
      -1   -- fall‑back in the very rare case the parameter is missing
    )                                                AS ga_session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')
                                                    AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
classified AS (
  -- label every url as PLP, PDP or OTHER
  SELECT
    *,
    CASE
      WHEN page_location IS NULL THEN NULL
      WHEN REGEXP_CONTAINS(
             LOWER(page_location),
             r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/')
           AND NOT REGEXP_CONTAINS(REGEXP_EXTRACT(page_location, r'/([^/?#]+)$'), r'\+')
        THEN 'PLP'
      WHEN REGEXP_CONTAINS(
             LOWER(page_location),
             r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/')
           AND REGEXP_CONTAINS(REGEXP_EXTRACT(page_location, r'/([^/?#]+)$'), r'\+')
        THEN 'PDP'
      ELSE NULL
    END AS page_type
  FROM page_views
),
plp AS (
  SELECT * FROM classified WHERE page_type = 'PLP'
),
pdp AS (
  SELECT * FROM classified WHERE page_type = 'PDP'
),
plp_with_transition_flag AS (
  /*  a PLP view “leads to” a PDP when, within the same
      user‑and‑session, a later PDP page_view exists                */
  SELECT
    p.*,
    EXISTS (
      SELECT 1
      FROM pdp d
      WHERE d.user_pseudo_id = p.user_pseudo_id
        AND d.ga_session_id  = p.ga_session_id
        AND d.event_timestamp > p.event_timestamp
    ) AS transitioned_to_pdp
  FROM plp p
)
SELECT
  COUNTIF(transitioned_to_pdp)                        AS plp_views_leading_to_pdp,
  COUNT(*)                                            AS total_plp_views,
  SAFE_DIVIDE(COUNTIF(transitioned_to_pdp), COUNT(*)) * 100
                                                      AS plp_to_pdp_percentage
FROM plp_with_transition_flag;