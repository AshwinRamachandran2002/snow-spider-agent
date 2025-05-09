-- Average purchase-session revenue per user (users with >1 purchase session), 1-30 Nov 2020
SELECT
  user_pseudo_id,
  AVG(session_revenue_usd) AS avg_purchase_revenue_usd_per_session,
  COUNT(*)                 AS purchase_sessions
FROM (
  SELECT
    user_pseudo_id,
    ep.value.int_value              AS ga_session_id,
    SUM(ecommerce.purchase_revenue_in_usd) AS session_revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
    AND ep.key = 'ga_session_id'
  GROUP BY user_pseudo_id, ga_session_id
)
GROUP BY user_pseudo_id
HAVING COUNT(*) > 1            -- only users with more than one purchase session
ORDER BY avg_purchase_revenue_usd_per_session DESC;