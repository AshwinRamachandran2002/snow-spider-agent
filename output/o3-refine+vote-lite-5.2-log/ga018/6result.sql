/*  PLP‑to‑PDP transition rate for 2 Jan 2021  */
WITH page_view AS (          -- 1.  all 2‑Jan page_view events + key params
  SELECT
    user_pseudo_id,
    (SELECT value.int_value
       FROM UNNEST(event_params) WHERE key = 'ga_session_id')          AS session_id,
    event_timestamp,
    (SELECT value.string_value
       FROM UNNEST(event_params) WHERE key = 'page_location')          AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
segmented AS (               -- 2. split URL into path segments
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    page_location,
    SPLIT(REGEXP_EXTRACT(page_location, r'://[^/]+/(.*)'), '/')        AS segments
  FROM page_view
  WHERE page_location IS NOT NULL
),
prepared AS (                -- 3.  helpers for classification
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    page_location,
    segments,
    ARRAY_LENGTH(segments)                                               AS seg_len,
    LOWER(REPLACE(segments[SAFE_OFFSET(3)], '+', ' '))                   AS seg4_norm,
    LOWER(REPLACE(segments[SAFE_OFFSET(4)], '+', ' '))                   AS seg5_norm,
    segments[SAFE_OFFSET(ARRAY_LENGTH(segments)-1)]                      AS last_seg
  FROM segmented
),
classified AS (             -- 4. mark each view as PLP / PDP / NULL
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    page_location,
    CASE
      WHEN is_category AND last_has_plus     THEN 'PDP'
      WHEN is_category AND NOT last_has_plus THEN 'PLP'
    END                                                             AS page_type
  FROM (
    SELECT
      *,
      ( seg_len >= 5 AND (
          seg4_norm IN ('accessories','apparel','brands','campus collection','drinkware','electronics',
                         'google redesign','lifestyle','nest','new 2015 logo','notebooks journals','office',
                         'shop by brand','small goods','stationery','wearables')
          OR
          seg5_norm IN ('accessories','apparel','brands','campus collection','drinkware','electronics',
                         'google redesign','lifestyle','nest','new 2015 logo','notebooks journals','office',
                         'shop by brand','small goods','stationery','wearables')
        )
      )                                               AS is_category,
      STRPOS(last_seg, '+') > 0                      AS last_has_plus
    FROM prepared
  )
),
labeled AS (                 -- 5. keep only rows we could classify
  SELECT *
  FROM classified
  WHERE page_type IS NOT NULL
),
plp AS (                     -- 6.  for every PLP decide if a later PDP happens in same session
  SELECT
    l.*,
    EXISTS (
      SELECT 1
      FROM labeled p
      WHERE p.page_type      = 'PDP'
        AND p.user_pseudo_id = l.user_pseudo_id
        AND p.session_id     = l.session_id
        AND p.event_timestamp > l.event_timestamp
    ) AS leads_to_pdp
  FROM labeled l
  WHERE l.page_type = 'PLP'
)
SELECT
  COUNT(*)                               AS total_plp_views,
  COUNTIF(leads_to_pdp)                  AS plp_views_leading_to_pdp,
  ROUND(SAFE_DIVIDE(COUNTIF(leads_to_pdp), COUNT(*)) * 100, 4)
      AS plp_to_pdp_percentage
FROM plp;