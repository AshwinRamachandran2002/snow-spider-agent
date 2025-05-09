/* PLP‑to‑PDP conversion rate for 2‑Jan‑2021 */
WITH pageviews AS (               -- all page_view events for the day
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id') AS session_id,
    event_timestamp,
    LOWER(                                   -- make url matching case‑insensitive
      (SELECT ep.value.string_value
         FROM UNNEST(event_params) ep
        WHERE ep.key = 'page_location')
    ) AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
/* classify each page_view as PLP / PDP / Other */
classified AS (
  SELECT *,
    CASE
      -- PDP: category in path and “+” in last segment
      WHEN REGEXP_CONTAINS(
             url,
             r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/'
           )
       AND REGEXP_CONTAINS(url, r'/[^/]*\+[^/]*$')
        THEN 'PDP'

      -- PLP: category in path but NO “+” in last segment
      WHEN REGEXP_CONTAINS(
             url,
             r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/'
           )
       AND NOT REGEXP_CONTAINS(url, r'/[^/]*\+[^/]*$')
        THEN 'PLP'

      ELSE 'Other'
    END AS page_type
  FROM pageviews
),

plp AS (SELECT * FROM classified WHERE page_type = 'PLP'),
pdp AS (SELECT * FROM classified WHERE page_type = 'PDP'),

/* PLP events that have ANY later PDP view in the same (user,session) */
plp_to_pdp AS (
  SELECT DISTINCT
         plp.user_pseudo_id,
         plp.session_id,
         plp.event_timestamp          -- identify the individual PLP event
  FROM plp
  JOIN pdp
    ON plp.user_pseudo_id = pdp.user_pseudo_id
   AND plp.session_id     = pdp.session_id
   AND pdp.event_timestamp > plp.event_timestamp
)

SELECT
  COUNT(*)                                    AS total_plp_views,
  (SELECT COUNT(*) FROM plp_to_pdp)           AS plp_with_pdp_afterwards,
  ROUND(
    100 * (SELECT COUNT(*) FROM plp_to_pdp) / COUNT(*), 2
  )                                           AS pct_plp_to_pdp
FROM plp;