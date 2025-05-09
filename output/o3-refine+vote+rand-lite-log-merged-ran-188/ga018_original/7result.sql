WITH base AS (
  -- collect all page_view events for 2 Jan 2021 and pull out the
  -- fields we need
  SELECT
    event_timestamp,
    user_pseudo_id,
    COALESCE(
      (SELECT ep.value.int_value
         FROM UNNEST(event_params) ep
        WHERE ep.key = 'ga_session_id'),
      0)                              AS session_id,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

/* -------------------------------------------------------------
   Classify each page_view as PLP or PDP
----------------------------------------------------------------*/
classified AS (
  SELECT
    event_timestamp,
    user_pseudo_id,
    session_id,
    page_location,

    /* helper pieces */
    ARRAY_LENGTH(SPLIT(page_location,'/'))                                         AS seg_len,
    LOWER(IF(ARRAY_LENGTH(SPLIT(page_location,'/')) > 3,
             SPLIT(page_location,'/')[OFFSET(3)], ''))                             AS seg4,
    LOWER(IF(ARRAY_LENGTH(SPLIT(page_location,'/')) > 4,
             SPLIT(page_location,'/')[OFFSET(4)], ''))                             AS seg5,
    LOWER(SPLIT(page_location,'/')[
          OFFSET(ARRAY_LENGTH(SPLIT(page_location,'/'))-1)])                       AS last_seg
  FROM base
),

/* add PLP / PDP flags using refined business rules */
flagged AS (
  SELECT
    event_timestamp,
    user_pseudo_id,
    session_id,
    page_location,

    -- PLP rules
    CASE
      WHEN seg_len >= 5
           AND (REGEXP_CONTAINS(seg4, category_rgx) OR REGEXP_CONTAINS(seg5, category_rgx))
           AND STRPOS(seg4,'+') = -1
           AND STRPOS(seg5,'+') = -1
      THEN 1 ELSE 0
    END AS is_plp,

    -- PDP rules
    CASE
      WHEN seg_len >= 5
           AND (REGEXP_CONTAINS(seg4, category_rgx) OR REGEXP_CONTAINS(seg5, category_rgx))
           AND STRPOS(last_seg,'+') > -1
      THEN 1 ELSE 0
    END AS is_pdp
  FROM classified,
  UNNEST([STRUCT(
    '(?i)(accessories|apparel|brands|campus\\+collection|drinkware|electronics|google\\+redesign|lifestyle|nest|new\\+2015\\+logo|notebooks\\+journals|office|shop\\+by\\+brand|small\\+goods|stationery|wearables)' AS category_rgx)])
),

/* -------------------------------------------------------------
   First PDP time stamp for every session
----------------------------------------------------------------*/
session_first_pdp AS (
  SELECT
    user_pseudo_id,
    session_id,
    MIN(event_timestamp) AS first_pdp_ts
  FROM flagged
  WHERE is_pdp = 1
  GROUP BY user_pseudo_id, session_id
),

/* -------------------------------------------------------------
   Mark each PLP view if it occurs before a PDP in the same session
----------------------------------------------------------------*/
plp_views AS (
  SELECT
    f.event_timestamp,
    IF(sp.first_pdp_ts IS NOT NULL
        AND sp.first_pdp_ts > f.event_timestamp,
       1, 0)                                    AS plp_leads_to_pdp
  FROM flagged f
  LEFT JOIN session_first_pdp sp
    ON  sp.user_pseudo_id = f.user_pseudo_id
    AND sp.session_id     = f.session_id
  WHERE f.is_plp = 1
)

/* -------------------------------------------------------------
   Final tallies and percentage
----------------------------------------------------------------*/
SELECT
  COUNT(*)                                               AS total_plp_views,
  COUNTIF(plp_leads_to_pdp = 1)                          AS plp_views_that_led_to_pdp,
  ROUND(SAFE_DIVIDE(
            COUNTIF(plp_leads_to_pdp = 1), COUNT(*)) * 100, 4)
                                                         AS plp_to_pdp_percentage
FROM plp_views;