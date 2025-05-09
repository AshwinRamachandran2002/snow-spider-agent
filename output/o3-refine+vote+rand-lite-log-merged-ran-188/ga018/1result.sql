-- Percentage of Product-List-Page (PLP) views that are followed by
-- a Product-Detail-Page (PDP) view in the same session
-- (2-Jan-2021, page_view events only)

WITH base AS (     -- pull the essentials once per page_view
  SELECT
    user_pseudo_id,
    COALESCE(                -- ga_session_id can be NULL
      ( SELECT ep.value.int_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'ga_session_id'
      ), -1)             AS ga_session_id,
    event_timestamp,
    LOWER(                 -- normalise to lower-case
      ( SELECT ep.value.string_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'page_location'
      )
    )                     AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

classified AS (           -- work out PLP vs PDP vs Other
  SELECT
    *,
    REGEXP_CONTAINS(       -- does the path contain a recognised category?
      url,
      r'/((accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables))/'
    )                                         AS has_category,
    REGEXP_CONTAINS(       -- does the *last* path segment contain a “+”?
      REGEXP_EXTRACT(url, r'https?://[^/]+(/.*)'),
      r'/[^/]*\+[^/]*$'
    )                                         AS last_seg_has_plus
  FROM base
),

labeled AS (
  SELECT
    *,
    CASE
      WHEN has_category AND last_seg_has_plus  THEN 'PDP'
      WHEN has_category AND NOT last_seg_has_plus THEN 'PLP'
      ELSE 'OTHER'
    END AS page_type
  FROM classified
),

plp_events AS (SELECT * FROM labeled WHERE page_type = 'PLP'),
pdp_events AS (SELECT user_pseudo_id, ga_session_id, event_timestamp FROM labeled WHERE page_type = 'PDP'),

plp_flagged AS (         -- for every PLP view, did a *later* PDP happen in the same session?
  SELECT
    p.*,
    EXISTS (
      SELECT 1
      FROM pdp_events d
      WHERE d.user_pseudo_id = p.user_pseudo_id
        AND d.ga_session_id  = p.ga_session_id
        AND d.event_timestamp > p.event_timestamp       -- later in time
    ) AS led_to_pdp
  FROM plp_events p
),

agg AS (
  SELECT
    COUNT(*)                           AS total_plp_views,
    COUNTIF(led_to_pdp)                AS plp_views_with_pdp
  FROM plp_flagged
)

SELECT
  total_plp_views,
  plp_views_with_pdp,
  ROUND(SAFE_DIVIDE(plp_views_with_pdp, total_plp_views) * 100, 4) AS pct_plp_to_pdp
FROM agg;