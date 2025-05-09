WITH purchase_events AS (   -- 1. keep only purchase events with revenue
  SELECT
    user_pseudo_id,
    -- pull the session id stored in the event parameters
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'ga_session_id'
      LIMIT 1) AS ga_session_id,
    ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_date BETWEEN '20201101' AND '20201130'
    AND event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
),

session_revenue AS (        -- 2. total purchase revenue per user‑session
  SELECT
    user_pseudo_id,
    ga_session_id,
    SUM(purchase_revenue_usd) AS session_revenue_usd
  FROM purchase_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
),

user_stats AS (             -- 3. average revenue per session per user
  SELECT
    user_pseudo_id,
    COUNT(*)                       AS purchase_session_count,
    AVG(session_revenue_usd)       AS avg_revenue_per_session_usd
  FROM session_revenue
  GROUP BY user_pseudo_id
  HAVING purchase_session_count > 1   -- keep users with >1 purchase sessions
)

SELECT
  user_pseudo_id,
  avg_revenue_per_session_usd AS average_purchase_revenue_usd_per_session
FROM user_stats
ORDER BY average_purchase_revenue_usd_per_session DESC;