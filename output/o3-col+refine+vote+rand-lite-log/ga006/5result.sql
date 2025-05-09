WITH session_revenue AS (        -- 1 row = 1 purchase-session
  SELECT
    e.user_pseudo_id,
    ep.value.int_value                     AS ga_session_id,
    SUM(e.ecommerce.purchase_revenue_in_usd) AS session_revenue_usd
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
  CROSS JOIN UNNEST(e.event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'   -- Nov 1-30 2020
    AND e.event_name = 'purchase'
    AND e.ecommerce.purchase_revenue_in_usd IS NOT NULL
    AND ep.key = 'ga_session_id'                          -- pull session ID
  GROUP BY e.user_pseudo_id, ga_session_id
)

SELECT
  user_pseudo_id,
  AVG(session_revenue_usd) AS avg_purchase_revenue_per_session
FROM session_revenue
GROUP BY user_pseudo_id
HAVING COUNT(*) > 1;        -- only users with >1 purchase session