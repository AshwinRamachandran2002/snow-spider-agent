/* Average purchase revenue per session (USD) for users with >1 purchase-session
   Date range: 2020-11-01 → 2020-11-30                                      */

SELECT
  user_pseudo_id,
  ROUND(AVG(session_revenue_usd),4) AS avg_purchase_revenue_per_session_usd
FROM (
  /* 1.  Revenue at session level --------------------------------------- */
  SELECT
    user_pseudo_id,
    ep.value.int_value                           AS ga_session_id,
    SUM(ecommerce.purchase_revenue_in_usd)       AS session_revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`,
  UNNEST(event_params) AS ep
  WHERE event_name = 'purchase'
    AND ep.key = 'ga_session_id'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
    AND event_date BETWEEN '20201101' AND '20201130'
  GROUP BY user_pseudo_id, ga_session_id
)
GROUP BY user_pseudo_id
HAVING COUNT(*) > 1            -- keep users with >1 purchase-session
ORDER BY avg_purchase_revenue_per_session_usd DESC;