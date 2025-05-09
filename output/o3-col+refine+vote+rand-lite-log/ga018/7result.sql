-- PLP-to-PDP transition rate for 02-Jan-2021 (page_view events only)
WITH base AS (        -- 1) Pull raw page_view rows + handy fields
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id')            AS session_id,
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location')            AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
classified AS (       -- 2) Label each view as PDP / PLP / OTHER
  SELECT
    *,
    CASE
      WHEN url IS NULL THEN 'OTHER'
      WHEN ARRAY_LENGTH(SPLIT(url,'/')) >= 5
           AND REGEXP_CONTAINS(
                 LOWER(SPLIT(url,'/')[ORDINAL(ARRAY_LENGTH(SPLIT(url,'/')))]),
                 r'\+')                                             -- “+” in last segment
           AND (
             REGEXP_CONTAINS(LOWER(SPLIT(url,'/')[OFFSET(3)]),
               r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
             OR
             REGEXP_CONTAINS(LOWER(SPLIT(url,'/')[OFFSET(4)]),
               r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
           )
        THEN 'PDP'
      WHEN ARRAY_LENGTH(SPLIT(url,'/')) >= 5
           AND NOT REGEXP_CONTAINS(
                 LOWER(SPLIT(url,'/')[ORDINAL(ARRAY_LENGTH(SPLIT(url,'/')))]),
                 r'\+')                                             -- NO “+” in last segment
           AND (
             REGEXP_CONTAINS(LOWER(SPLIT(url,'/')[OFFSET(3)]),
               r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
             OR
             REGEXP_CONTAINS(LOWER(SPLIT(url,'/')[OFFSET(4)]),
               r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
           )
        THEN 'PLP'
      ELSE 'OTHER'
    END AS page_type
  FROM base
),
first_pdp AS (        -- 3) First PDP moment per session
  SELECT
    user_pseudo_id,
    session_id,
    MIN(event_timestamp) AS first_pdp_ts
  FROM classified
  WHERE page_type = 'PDP'
  GROUP BY user_pseudo_id, session_id
),
plp_flags AS (        -- 4) Mark each PLP view if a later PDP exists
  SELECT
    c.event_timestamp,
    fp.first_pdp_ts
  FROM classified AS c
  LEFT JOIN first_pdp AS fp
    ON fp.user_pseudo_id = c.user_pseudo_id
   AND fp.session_id     = c.session_id
  WHERE c.page_type = 'PLP'
)
-- 5) Final metrics
SELECT
  COUNT(*)                                               AS total_plp_views,
  COUNTIF(first_pdp_ts > event_timestamp)                AS plp_views_with_pdp_after,
  ROUND( SAFE_DIVIDE(
           COUNTIF(first_pdp_ts > event_timestamp),
           COUNT(*)
         ), 4)                                           AS plp_to_pdp_transition_pct
FROM plp_flags;