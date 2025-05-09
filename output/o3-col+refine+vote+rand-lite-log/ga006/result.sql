-- Average purchase-revenue (USD) per session for users with >1 purchase session
-- during 1–30 November 2020
WITH purchase_events AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) AS ep
       WHERE ep.key = 'ga_session_id'
       LIMIT 1)              AS ga_session_id,
    ecommerce.purchase_revenue_in_usd AS revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'  -- 1–30 Nov 2020
    AND event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
),
session_revenue AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    SUM(revenue_usd) AS session_revenue_usd
  FROM purchase_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
),
user_stats AS (
  SELECT
    user_pseudo_id,
    COUNT(*)                 AS purchase_session_cnt,
    AVG(session_revenue_usd) AS avg_rev_per_session_usd
  FROM session_revenue
  GROUP BY user_pseudo_id
)
SELECT
  user_pseudo_id,
  avg_rev_per_session_usd
FROM user_stats
WHERE purchase_session_cnt > 1       -- only users with >1 purchase session
ORDER BY avg_rev_per_session_usd DESC;