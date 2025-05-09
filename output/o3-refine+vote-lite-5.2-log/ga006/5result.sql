-- Average purchase revenue (USD) per session for users
-- who had more than one purchase session in Nov 1–30 2020
WITH purchase_events AS (
  SELECT
    user_pseudo_id,
    -- extract ga_session_id from event_params
    (
      SELECT ep.value.int_value
      FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'ga_session_id'
    ) AS ga_session_id,
    ecommerce.purchase_revenue_in_usd AS revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  -- read only November 1–30 2020 partitioned tables
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
),
session_revenue AS (
  -- total purchase revenue per user‑session
  SELECT
    user_pseudo_id,
    ga_session_id,
    SUM(revenue_usd) AS session_revenue_usd
  FROM purchase_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
)
SELECT
  user_pseudo_id,
  AVG(session_revenue_usd) AS avg_purchase_revenue_usd_per_session
FROM session_revenue
GROUP BY user_pseudo_id
HAVING COUNT(ga_session_id) > 1   -- users with >1 purchase session
ORDER BY avg_purchase_revenue_usd_per_session DESC;