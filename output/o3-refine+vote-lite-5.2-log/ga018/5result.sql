-- PLP‑to‑PDP transition rate for 02‑Jan‑2021
WITH page_views AS (                  -- keep only page_view events on 2021‑01‑02
  SELECT
    user_pseudo_id,
    COALESCE( (SELECT ep.value.int_value
               FROM UNNEST(event_params) ep
               WHERE ep.key = 'ga_session_id'), 0)              AS session_id,
    event_timestamp,
    (SELECT ep.value.string_value
     FROM   UNNEST(event_params) ep
     WHERE  ep.key = 'page_location')                          AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
classified AS (                       -- split the URL path into segments
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    url,
    SPLIT(REGEXP_EXTRACT(LOWER(url), r'://[^/]+/(.*)'), '/')   AS segments
  FROM page_views
),
flags AS (                            -- attach the category regexp once
  SELECT
    c.*,
    r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
      AS cat_re
  FROM classified c
),
marked AS (                           -- mark each page view as PLP or PDP
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    CASE
      WHEN ARRAY_LENGTH(segments) >= 5
       AND (REGEXP_CONTAINS(segments[OFFSET(3)], cat_re)
            OR REGEXP_CONTAINS(segments[OFFSET(4)], cat_re))
       AND NOT REGEXP_CONTAINS(segments[SAFE_OFFSET(3)], r'\+')
       AND NOT REGEXP_CONTAINS(segments[SAFE_OFFSET(4)], r'\+')
      THEN TRUE ELSE FALSE
    END                                                     AS is_plp,
    CASE
      WHEN ARRAY_LENGTH(segments) >= 5
       AND (REGEXP_CONTAINS(segments[OFFSET(3)], cat_re)
            OR REGEXP_CONTAINS(segments[OFFSET(4)], cat_re))
       AND REGEXP_CONTAINS(segments[OFFSET(ARRAY_LENGTH(segments)-1)], r'\+')
      THEN TRUE ELSE FALSE
    END                                                     AS is_pdp
  FROM flags
),
plps AS ( SELECT user_pseudo_id, session_id, event_timestamp FROM marked WHERE is_plp ),
pdps AS ( SELECT user_pseudo_id, session_id, event_timestamp FROM marked WHERE is_pdp ),

transition_check AS (                 -- did a later PDP occur in same session?
  SELECT
    plp.user_pseudo_id,
    plp.session_id,
    plp.event_timestamp                                  AS plp_ts,
    IF(MIN(pdp.event_timestamp) IS NOT NULL, 1, 0)       AS transitioned
  FROM plps plp
  LEFT JOIN pdps pdp
    ON  pdp.user_pseudo_id = plp.user_pseudo_id
    AND pdp.session_id     = plp.session_id
    AND pdp.event_timestamp> plp.event_timestamp
  GROUP BY plp.user_pseudo_id, plp.session_id, plp.event_timestamp
)

SELECT
  COUNT(*)                                             AS total_plp_views,
  SUM(transitioned)                                    AS plp_to_pdp_views,
  ROUND(SUM(transitioned)/COUNT(*)*100, 4)             AS plp_to_pdp_percentage
FROM transition_check;