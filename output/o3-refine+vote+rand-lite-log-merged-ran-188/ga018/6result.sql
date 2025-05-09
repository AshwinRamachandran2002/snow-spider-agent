/*  PLP-to-PDP transition rate for 2-Jan-2021  */

WITH pageviews AS (
  /* turn every page_view row into one record with url, session, timestamp */
  SELECT
    e.user_pseudo_id,
    MAX( CASE WHEN ep.key = 'ga_session_id' THEN ep.value.int_value    END ) AS session_id,
    MAX( CASE WHEN ep.key = 'page_location' THEN ep.value.string_value END ) AS url,
    e.event_timestamp
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS e
  CROSS JOIN UNNEST(e.event_params) AS ep
  WHERE e.event_name = 'page_view'
  GROUP BY e.user_pseudo_id, e.event_timestamp
),
classified AS (
  /* tag each url as PDP, PLP, or OTHER per briefing rules */
  SELECT
    *,
    CASE
      /* PDP  = category path + "+" in last segment                  */
      WHEN REGEXP_CONTAINS(LOWER(url),
           r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
       AND REGEXP_CONTAINS(LOWER(url), r'/[^/]*\+[^/]*$')
        THEN 'PDP'

      /* PLP = category path, but NO "+" in last segment              */
      WHEN REGEXP_CONTAINS(LOWER(url),
           r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
       AND NOT REGEXP_CONTAINS(LOWER(url), r'/[^/]*\+[^/]*$')
        THEN 'PLP'

      ELSE 'OTHER'
    END AS page_type
  FROM pageviews
),
plp AS (
  SELECT * FROM classified WHERE page_type = 'PLP'
),
pdp AS (
  SELECT * FROM classified WHERE page_type = 'PDP'
),
plp_flagged AS (
  /* mark each PLP if a PDP occurs later in the same session */
  SELECT
    p.*,
    EXISTS (
      SELECT 1
      FROM   pdp d
      WHERE  d.user_pseudo_id = p.user_pseudo_id
        AND  d.session_id     = p.session_id
        AND  d.event_timestamp > p.event_timestamp     -- later in session
    ) AS led_to_pdp
  FROM plp p
)
SELECT
  COUNTIF(led_to_pdp)                             AS plp_views_that_led_to_pdp,
  COUNT(*)                                        AS total_plp_views,
  ROUND(100 * COUNTIF(led_to_pdp) / COUNT(*),2)   AS pct_plp_to_pdp
FROM plp_flagged;