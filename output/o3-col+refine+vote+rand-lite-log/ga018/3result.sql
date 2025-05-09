WITH page_views AS (
  -- January-02-2021 page_view rows with the 3 fields we need
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id')                               AS ga_session_id,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'page_location')                               AS page_location,
    event_timestamp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

classified AS (
  -- tag each URL as PDP or PLP according to the refined rules
  SELECT
    pv.*,
    REGEXP_CONTAINS(page_location, r'/[^/]*\+[^/]*$')                AS is_pdp,
    ( REGEXP_CONTAINS(LOWER(page_location),
        r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
      AND NOT REGEXP_CONTAINS(page_location, r'/[^/]*\+[^/]*$') )    AS is_plp
  FROM page_views pv
),

plp_flagged AS (
  -- for every PLP view, check if a later PDP occurs in the same session
  SELECT
    c.*,
    EXISTS (
      SELECT 1
      FROM classified AS later
      WHERE later.user_pseudo_id = c.user_pseudo_id
        AND later.ga_session_id  = c.ga_session_id
        AND later.is_pdp         = TRUE
        AND later.event_timestamp > c.event_timestamp
    ) AS plp_followed_by_pdp
  FROM classified c
  WHERE is_plp
)

-- final counts & percentage
SELECT
  COUNT(*)                                                           AS total_plp_views,
  SUM(CASE WHEN plp_followed_by_pdp THEN 1 ELSE 0 END)               AS plp_views_leading_to_pdp,
  ROUND(
    100 * SUM(CASE WHEN plp_followed_by_pdp THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),                                       
    2
  )                                                                  AS pct_plp_to_pdp
FROM plp_flagged;