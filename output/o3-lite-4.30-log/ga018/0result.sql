WITH base AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value    FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    event_timestamp,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_date = '20210102'
    AND event_name = 'page_view'
),
tagged AS (
  SELECT *,
         CASE
           /* PDP: category present AND '+' in the last segment */
           WHEN REGEXP_CONTAINS(LOWER(url),
                 r'/((accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)(/|$))')
             AND REGEXP_CONTAINS(url, r'/[^/]*\+[^/]*$')
           THEN 'PDP'

           /* PLP: category present AND no '+' in the last segment */
           WHEN REGEXP_CONTAINS(LOWER(url),
                 r'/((accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)(/|$))')
             AND NOT REGEXP_CONTAINS(url, r'/[^/]*\+[^/]*$')
           THEN 'PLP'
           ELSE 'OTHER'
         END AS page_type
  FROM base
),
session_steps AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    MIN(IF(page_type = 'PLP', event_timestamp, NULL)) AS first_plp_ts,
    MIN(IF(page_type = 'PDP', event_timestamp, NULL)) AS first_pdp_ts
  FROM tagged
  GROUP BY user_pseudo_id, ga_session_id
),
valid_sessions AS (
  SELECT user_pseudo_id, ga_session_id
  FROM session_steps
  WHERE first_plp_ts IS NOT NULL
    AND first_pdp_ts IS NOT NULL
    AND first_pdp_ts > first_plp_ts
),
final_counts AS (
  SELECT
    (SELECT COUNT(*) FROM tagged WHERE page_type = 'PLP') AS plp_views,
    (SELECT COUNT(*)
       FROM tagged t
       JOIN valid_sessions s
         ON t.user_pseudo_id = s.user_pseudo_id
        AND t.ga_session_id  = s.ga_session_id
      WHERE t.page_type = 'PLP')                          AS pdp_transitions
)
SELECT
  plp_views,
  pdp_transitions,
  ROUND(100 * SAFE_DIVIDE(pdp_transitions, plp_views), 4) AS transition_percentage
FROM final_counts