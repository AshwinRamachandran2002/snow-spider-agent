WITH base AS (
  -- all page_view events for 02‑Jan‑2021 -----------------------------
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'ga_session_id')                       AS ga_session_id,
    event_timestamp,
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'page_location')                       AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_date = '20210102'
    AND event_name = 'page_view'
),
typed AS (
  -- classify each page_view ------------------------------------------
  SELECT
    user_pseudo_id, ga_session_id, event_timestamp, url,
    CASE
      -- Product Listing Page (PLP)
      WHEN ARRAY_LENGTH(SPLIT(url,'/')) >= 5
           AND NOT REGEXP_CONTAINS(SPLIT(url,'/')[ORDINAL(ARRAY_LENGTH(SPLIT(url,'/')))], r'\+')
           AND (
                REGEXP_CONTAINS(
                  LOWER(REPLACE(SPLIT(url,'/')[OFFSET(3)], '+', ' ')),
                  r'(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)')
             OR REGEXP_CONTAINS(
                  LOWER(REPLACE(SPLIT(url,'/')[OFFSET(4)], '+', ' ')),
                  r'(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)')
               )
           THEN 'PLP'
      -- Product Detail Page (PDP)
      WHEN ARRAY_LENGTH(SPLIT(url,'/')) >= 5
           AND REGEXP_CONTAINS(SPLIT(url,'/')[ORDINAL(ARRAY_LENGTH(SPLIT(url,'/')))], r'\+')
           AND (
                REGEXP_CONTAINS(
                  LOWER(REPLACE(SPLIT(url,'/')[OFFSET(3)], '+', ' ')),
                  r'(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)')
             OR REGEXP_CONTAINS(
                  LOWER(REPLACE(SPLIT(url,'/')[OFFSET(4)], '+', ' ')),
                  r'(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)')
               )
           THEN 'PDP'
      ELSE 'OTHER'
    END AS page_type
  FROM base
),
first_pdp AS (
  -- first PDP timestamp per session ----------------------------------
  SELECT
    user_pseudo_id,
    ga_session_id,
    MIN(event_timestamp) AS first_pdp_ts
  FROM typed
  WHERE page_type = 'PDP'
  GROUP BY user_pseudo_id, ga_session_id
),
plp_views AS (
  -- every individual PLP view with PDP info --------------------------
  SELECT
    t.user_pseudo_id,
    t.ga_session_id,
    t.event_timestamp AS plp_ts,
    f.first_pdp_ts
  FROM typed t
  LEFT JOIN first_pdp f
    USING (user_pseudo_id, ga_session_id)
  WHERE t.page_type = 'PLP'
)
-- final aggregation --------------------------------------------------
SELECT
  COUNT(*)                                                    AS plp_views,
  COUNTIF(first_pdp_ts IS NOT NULL AND plp_ts < first_pdp_ts) AS pdp_transitions,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(first_pdp_ts IS NOT NULL AND plp_ts < first_pdp_ts),
      COUNT(*)
    ) * 100, 4
  )                                                           AS transition_percentage
FROM plp_views;