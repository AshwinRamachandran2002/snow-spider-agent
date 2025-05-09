WITH base AS (   ----------------------------------------------------------------
  -- All 2021‑01‑02 page_view events with the fields we need
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id')            AS session_id,
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location')            AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
classified AS (  ---------------------------------------------------------------
  -- Classify each page_location as PLP or PDP
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    CASE
      /* PDP criteria */
      WHEN ARRAY_LENGTH(seg) >= 5
           AND (
             REGEXP_CONTAINS(seg[SAFE_OFFSET(3)],
               r'(?i)(Accessories|Apparel|Brands|Campus\+Collection|Drinkware|Electronics|Google\+Redesign|Lifestyle|Nest|New\+2015\+Logo|Notebooks\+Journals|Office|Shop\+by\+Brand|Small\+Goods|Stationery|Wearables)')
             OR
             REGEXP_CONTAINS(seg[SAFE_OFFSET(4)],
               r'(?i)(Accessories|Apparel|Brands|Campus\+Collection|Drinkware|Electronics|Google\+Redesign|Lifestyle|Nest|New\+2015\+Logo|Notebooks\+Journals|Office|Shop\+by\+Brand|Small\+Goods|Stationery|Wearables)')
           )
           AND REGEXP_CONTAINS(seg[SAFE_OFFSET(ARRAY_LENGTH(seg)-1)], r'\+')
        THEN 'PDP'

      /* PLP criteria */
      WHEN ARRAY_LENGTH(seg) >= 5
           AND (
             REGEXP_CONTAINS(seg[SAFE_OFFSET(3)],
               r'(?i)(Accessories|Apparel|Brands|Campus\+Collection|Drinkware|Electronics|Google\+Redesign|Lifestyle|Nest|New\+2015\+Logo|Notebooks\+Journals|Office|Shop\+by\+Brand|Small\+Goods|Stationery|Wearables)')
             OR
             REGEXP_CONTAINS(seg[SAFE_OFFSET(4)],
               r'(?i)(Accessories|Apparel|Brands|Campus\+Collection|Drinkware|Electronics|Google\+Redesign|Lifestyle|Nest|New\+2015\+Logo|Notebooks\+Journals|Office|Shop\+by\+Brand|Small\+Goods|Stationery|Wearables)')
           )
           AND NOT REGEXP_CONTAINS(seg[SAFE_OFFSET(ARRAY_LENGTH(seg)-1)], r'\+')
        THEN 'PLP'
    END AS page_type
  FROM (
    SELECT
      user_pseudo_id,
      session_id,
      event_timestamp,
      page_location,
      SPLIT(REGEXP_REPLACE(page_location, r'^https?://', ''), '/') AS seg
    FROM base
    WHERE page_location IS NOT NULL
      AND session_id   IS NOT NULL
  )
)
, filtered AS (  ---------------------------------------------------------------
  -- keep only PLP and PDP rows
  SELECT user_pseudo_id, session_id, event_timestamp, page_type
  FROM   classified
  WHERE  page_type IS NOT NULL
)
, plp_events AS (
  SELECT user_pseudo_id, session_id, event_timestamp
  FROM   filtered
  WHERE  page_type = 'PLP'
)
, pdp_events AS (
  SELECT user_pseudo_id, session_id, event_timestamp
  FROM   filtered
  WHERE  page_type = 'PDP'
)
, plp_with_following_pdp AS ( -----------------------------------------------
  -- PLP views followed by at least one later PDP in same session
  SELECT DISTINCT p.user_pseudo_id, p.session_id, p.event_timestamp
  FROM plp_events p
  JOIN pdp_events d
    ON d.user_pseudo_id = p.user_pseudo_id
   AND d.session_id     = p.session_id
   AND d.event_timestamp > p.event_timestamp
)
SELECT
  COUNT(*)                                                        AS total_plp_views,
  (SELECT COUNT(*) FROM plp_with_following_pdp)                   AS plp_to_pdp_views,
  SAFE_DIVIDE(
      (SELECT COUNT(*) FROM plp_with_following_pdp),
      COUNT(*)
  ) * 100                                                         AS plp_to_pdp_percentage
FROM plp_events;