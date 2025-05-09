-- Conversion rate for 2-Jan-2021 based on GA4 page_view events
WITH home_sessions AS (        -- sessions that landed on the Home page
  SELECT DISTINCT
         ev.user_pseudo_id,
         CAST(gs.value.int_value AS INT64) AS ga_session_id
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` ev
  CROSS JOIN UNNEST(ev.event_params) pt
  CROSS JOIN UNNEST(ev.event_params) gs
  WHERE ev.event_name = 'page_view'
    AND pt.key = 'page_title'
    AND pt.value.string_value = 'Google Online Store'       -- Home page title
    AND gs.key = 'ga_session_id'
),

checkout_sessions AS (         -- sessions that reached Checkout Confirmation
  SELECT DISTINCT
         ev.user_pseudo_id,
         CAST(gs.value.int_value AS INT64) AS ga_session_id
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` ev
  CROSS JOIN UNNEST(ev.event_params) pt
  CROSS JOIN UNNEST(ev.event_params) gs
  WHERE ev.event_name = 'page_view'
    AND pt.key = 'page_title'
    AND LOWER(pt.value.string_value) LIKE '%confirm%'        -- confirmation page
    AND gs.key = 'ga_session_id'
)

SELECT
  COUNT(DISTINCT CONCAT(hs.user_pseudo_id,'-',hs.ga_session_id))                      AS home_sessions,
  COUNT(DISTINCT CONCAT(cs.user_pseudo_id,'-',cs.ga_session_id))                      AS home_and_checkout,
  ROUND(
    100 * COUNT(DISTINCT CONCAT(cs.user_pseudo_id,'-',cs.ga_session_id))
        / NULLIF(COUNT(DISTINCT CONCAT(hs.user_pseudo_id,'-',hs.ga_session_id)),0)
  ,4)                                                                                 AS conversion_rate_percent
FROM home_sessions hs
LEFT JOIN checkout_sessions cs
  ON  cs.user_pseudo_id = hs.user_pseudo_id
  AND cs.ga_session_id  = hs.ga_session_id;