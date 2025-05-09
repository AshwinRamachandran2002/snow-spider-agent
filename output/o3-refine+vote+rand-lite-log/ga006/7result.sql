WITH purchase_events AS (
  /* 1. keep only purchase events (with revenue) between 01‑Nov and 30‑Nov‑2020 */
  SELECT
    user_pseudo_id,
    /* 2. extract the GA session id from the event parameters */
    (
      SELECT CAST(p.value.int_value AS INT64)
      FROM UNNEST(event_params) AS p
      WHERE p.key = 'ga_session_id'
      LIMIT 1
    ) AS session_id,
    ecommerce.purchase_revenue_in_usd AS revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
),

session_revenue AS (
  /* 3. sum revenue per (user, session) */
  SELECT
    user_pseudo_id,
    session_id,
    SUM(revenue_usd) AS session_revenue_usd
  FROM purchase_events
  WHERE session_id IS NOT NULL
  GROUP BY user_pseudo_id, session_id
),

user_averages AS (
  /* 4. average session revenue per user; keep users with >1 purchase session */
  SELECT
    user_pseudo_id,
    COUNT(*)  AS purchase_sessions,
    AVG(session_revenue_usd) AS avg_purchase_revenue_per_session_usd
  FROM session_revenue
  GROUP BY user_pseudo_id
  HAVING purchase_sessions > 1
)

-- 5. final result
SELECT
  user_pseudo_id,
  ROUND(avg_purchase_revenue_per_session_usd, 4) AS avg_purchase_revenue_per_session_usd
FROM user_averages
ORDER BY avg_purchase_revenue_per_session_usd DESC, user_pseudo_id;