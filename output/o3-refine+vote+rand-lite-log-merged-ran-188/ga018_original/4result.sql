/*  PLP → PDP transition rate for 02‑Jan‑2021  */

WITH page_views AS (                    -- raw page_view rows
  SELECT
    user_pseudo_id,
    COALESCE(                           -- GA4 session id
      (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id'), -1)      AS session_id,
    event_timestamp,
    LOWER(                               -- page URL
      (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'page_location'))             AS page_url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

classified AS (                          -- derive helpers
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    page_url,
    SPLIT(page_url,'/')                           AS seg,
    REGEXP_EXTRACT(page_url,r'[^/]+$')            AS last_part
  FROM page_views
),

labeled AS (                              -- assign page_type
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    page_url,
    CASE
      WHEN page_url IS NULL THEN 'OTHER'
      ELSE
        CASE
          -- PDP  (≥5 segments, last part has '+', 4th or 5th seg is category)
          WHEN ARRAY_LENGTH(seg) >= 5
               AND REGEXP_CONTAINS(last_part, r'\+')
               AND (
                    REGEXP_CONTAINS(seg[OFFSET(3)],
                      r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
                 OR REGEXP_CONTAINS(seg[OFFSET(4)],
                      r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
               ) THEN 'PDP'

          -- PLP  (same category rule but last part lacks '+')
          WHEN ARRAY_LENGTH(seg) >= 5
               AND NOT REGEXP_CONTAINS(last_part, r'\+')
               AND (
                    REGEXP_CONTAINS(seg[OFFSET(3)],
                      r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
                 OR REGEXP_CONTAINS(seg[OFFSET(4)],
                      r'(?i)(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
               ) THEN 'PLP'

          ELSE 'OTHER'
        END
    END AS page_type
  FROM classified
),

session_first_pdp AS (                    -- first PDP in each session
  SELECT
    user_pseudo_id,
    session_id,
    MIN(event_timestamp) AS first_pdp_ts
  FROM labeled
  WHERE page_type = 'PDP'
  GROUP BY user_pseudo_id, session_id
),

plp_events AS (                           -- PLP views & whether they lead to PDP
  SELECT
    l.event_timestamp,
    CASE
      WHEN s.first_pdp_ts IS NOT NULL
           AND l.event_timestamp < s.first_pdp_ts THEN 1
      ELSE 0
    END AS leads_to_pdp
  FROM labeled AS l
  LEFT JOIN session_first_pdp AS s
    ON  l.user_pseudo_id = s.user_pseudo_id
    AND l.session_id     = s.session_id
  WHERE l.page_type = 'PLP'
    AND l.session_id <> -1                        -- ignore missing session ids
)

SELECT
  COUNT(*)                         AS total_plp_views,
  SUM(leads_to_pdp)                AS plp_views_that_led_to_pdp,
  SAFE_MULTIPLY(
    SAFE_DIVIDE(SUM(leads_to_pdp), COUNT(*)), 100
  )                                AS plp_to_pdp_percentage
FROM plp_events;