-- Average purchase‑revenue (USD) per session for users
-- who had more than one purchase session between
-- 1 Nov 2020 and 30 Nov 2020 (inclusive)

WITH purchase_sessions AS (
  -- 1. keep only purchase events with a revenue value
  -- 2. pull the ga_session_id from event_params
  SELECT
    e.user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(e.event_params) AS ep
      WHERE ep.key = 'ga_session_id') AS ga_session_id,
    e.ecommerce.purchase_revenue_in_usd            AS event_revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND e.event_name = 'purchase'
    AND e.ecommerce.purchase_revenue_in_usd IS NOT NULL
),
session_revenue AS (
  -- sum revenue inside the same user/session (safety in case of duplicates)
  SELECT
    user_pseudo_id,
    ga_session_id,
    SUM(event_revenue_usd) AS session_revenue_usd
  FROM purchase_sessions
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
),
user_metrics AS (
  -- compute number of purchase sessions and the average revenue per session
  SELECT
    user_pseudo_id,
    COUNT(*)                              AS purchase_session_cnt,
    AVG(session_revenue_usd)              AS avg_revenue_per_session_usd
  FROM session_revenue
  GROUP BY user_pseudo_id
)
SELECT
  user_pseudo_id,
  ROUND(avg_revenue_per_session_usd, 4)   AS avg_purchase_revenue_per_session_usd
FROM user_metrics
WHERE purchase_session_cnt > 1;