WITH pageviews AS (
  -- 1. Pull every page_view hit on 2-Jan-2021 together with URL and session identifiers
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'ga_session_id')        AS session_id,
    event_timestamp,
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'page_location')        AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
classified AS (
  -- 2. Classify each URL as PDP, PLP or OTHER
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    CASE
      WHEN REGEXP_CONTAINS(LOWER(url),
           r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
       AND REGEXP_CONTAINS(url, r'\+[^/]*$')              THEN 'PDP'
      WHEN REGEXP_CONTAINS(LOWER(url),
           r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
       AND NOT REGEXP_CONTAINS(url, r'\+[^/]*$')          THEN 'PLP'
      ELSE 'OTHER'
    END AS page_type
  FROM pageviews
),
first_pdp AS (
  -- 3. First PDP timestamp per (user, session)
  SELECT
    user_pseudo_id,
    session_id,
    MIN(event_timestamp) AS first_pdp_ts
  FROM classified
  WHERE page_type = 'PDP'
  GROUP BY user_pseudo_id, session_id
),
plp_flag AS (
  -- 4. For every PLP hit, flag if a later PDP happened in the same session
  SELECT
    c.user_pseudo_id,
    c.session_id,
    CASE
      WHEN f.first_pdp_ts IS NOT NULL
           AND f.first_pdp_ts > c.event_timestamp THEN 1
      ELSE 0
    END AS led_to_pdp
  FROM classified AS c
  LEFT JOIN first_pdp AS f
    ON  c.user_pseudo_id = f.user_pseudo_id
    AND c.session_id     = f.session_id
  WHERE c.page_type = 'PLP'
)
-- 5. Final counts and percentage
SELECT
  SUM(led_to_pdp)                           AS plp_that_led_to_pdp,
  COUNT(*)                                  AS total_plp_views,
  ROUND(100 * SAFE_DIVIDE(SUM(led_to_pdp),
                          COUNT(*)), 2)     AS pct_plp_to_pdp
FROM plp_flag;