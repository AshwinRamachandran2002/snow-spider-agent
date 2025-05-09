-- PLP‑to‑PDP transition rate for 2‑Jan‑2021
WITH page_views AS (   -- only page_view events for the day
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id')                    AS ga_session_id,
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location')                    AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
filtered AS (          -- keep rows that have both session id and URL
  SELECT *
  FROM page_views
  WHERE ga_session_id IS NOT NULL
    AND page_location IS NOT NULL
),
segments AS (          -- break the URL into path segments
  SELECT
    user_pseudo_id,
    ga_session_id,
    event_timestamp,
    page_location,
    SPLIT(LOWER(page_location), '/')                    AS segs
  FROM filtered
),
classified AS (        -- tag every view as PLP / PDP / OTHER
  SELECT
    user_pseudo_id,
    ga_session_id,
    event_timestamp,
    page_location,
    CASE
      WHEN seg_cnt >= 5
           AND (REGEXP_CONTAINS(seg4 , cat_re) OR REGEXP_CONTAINS(seg5 , cat_re))
           AND REGEXP_CONTAINS(last_seg , r'\+')                  THEN 'PDP'
      WHEN seg_cnt >= 5
           AND (REGEXP_CONTAINS(seg4 , cat_re) OR REGEXP_CONTAINS(seg5 , cat_re))
           AND NOT REGEXP_CONTAINS(last_seg , r'\+')              THEN 'PLP'
      ELSE 'OTHER'
    END AS page_type
  FROM (
    SELECT
      s.*,
      ARRAY_LENGTH(segs)                                AS seg_cnt,
      segs[SAFE_OFFSET(3)]                              AS seg4,        -- 4th segment
      segs[SAFE_OFFSET(4)]                              AS seg5,        -- 5th segment
      segs[SAFE_OFFSET(ARRAY_LENGTH(segs)-1)]           AS last_seg,    -- last segment
      '(accessories|apparel|brands|campus\\+collection|drinkware|electronics|google\\+redesign|lifestyle|nest|new\\+2015\\+logo|notebooks\\+journals|office|shop\\+by\\+brand|small\\+goods|stationery|wearables)'
                                                       AS cat_re
    FROM segments s
  )
),
plp_events AS (        -- all PLP views
  SELECT user_pseudo_id, ga_session_id, event_timestamp
  FROM classified
  WHERE page_type = 'PLP'
),
pdp_events AS (        -- all PDP views
  SELECT user_pseudo_id, ga_session_id, event_timestamp
  FROM classified
  WHERE page_type = 'PDP'
),
plp_with_transition AS (  -- PLP views that were followed by a PDP view in the same session
  SELECT DISTINCT plp.user_pseudo_id,
                  plp.ga_session_id,
                  plp.event_timestamp
  FROM plp_events plp
  JOIN pdp_events pdp
    ON  plp.user_pseudo_id = pdp.user_pseudo_id
    AND plp.ga_session_id  = pdp.ga_session_id
    AND pdp.event_timestamp > plp.event_timestamp
)
SELECT
  COUNT(*)                                            AS plp_views_that_led_to_pdp,
  (SELECT COUNT(*) FROM plp_events)                   AS total_plp_views,
  ROUND(100 * COUNT(*) /
        NULLIF((SELECT COUNT(*) FROM plp_events),0),4) AS percentage_plp_to_pdp
FROM plp_with_transition;