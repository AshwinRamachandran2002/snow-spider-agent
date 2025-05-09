-- Average purchase-revenue (USD) per session for users
-- with more than one purchase session in Nov-01–30-2020
WITH purchase_events AS (
  SELECT
    user_pseudo_id,
    -- extract ga_session_id from the nested event_params array
    (
      SELECT CAST(p.value.int_value AS INT64)
      FROM UNNEST(event_params) AS p
      WHERE p.key = 'ga_session_id'
    )                           AS ga_session_id,
    ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '30'        -- Nov-01 … Nov-30 2020
    AND event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
),
session_revenue AS (           -- sum revenue per (user, session)
  SELECT
    user_pseudo_id,
    ga_session_id,
    SUM(purchase_revenue_usd) AS session_revenue_usd
  FROM purchase_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
)
SELECT
  user_pseudo_id,
  AVG(session_revenue_usd) AS avg_purchase_revenue_usd_per_session
FROM session_revenue
GROUP BY user_pseudo_id
HAVING COUNT(DISTINCT ga_session_id) > 1           -- users with >1 purchase session
ORDER BY avg_purchase_revenue_usd_per_session DESC;