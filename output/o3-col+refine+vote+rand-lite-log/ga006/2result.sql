-- Average purchase-revenue (USD) per session for users with >1 purchase-session
-- across 1–30 Nov 2020
WITH purchases AS (
  SELECT
    user_pseudo_id,
    -- session id stored in event_params
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) AS ep
     WHERE ep.key = 'ga_session_id') AS session_id,
    ecommerce.purchase_revenue_in_usd AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'          -- Nov 1–30 2020
    AND event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
),
session_revenue AS (          -- total revenue per (user, session)
  SELECT
    user_pseudo_id,
    session_id,
    SUM(revenue) AS session_revenue_usd
  FROM purchases
  GROUP BY user_pseudo_id, session_id
),
user_stats AS (               -- users with >1 purchase-session
  SELECT
    user_pseudo_id,
    COUNT(*)                                   AS purchase_sessions,
    AVG(session_revenue_usd)                   AS avg_revenue_per_session_usd
  FROM session_revenue
  GROUP BY user_pseudo_id
  HAVING purchase_sessions > 1
)
SELECT
  user_pseudo_id,
  avg_revenue_per_session_usd
FROM user_stats
ORDER BY avg_revenue_per_session_usd DESC;