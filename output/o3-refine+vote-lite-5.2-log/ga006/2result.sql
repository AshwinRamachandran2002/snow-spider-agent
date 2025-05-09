/*  Average purchase revenue (USD) per session
    for users who had more than one purchase session
    between 1–30 Nov 2020                                   */

WITH purchase_events AS (         -- 1. purchase events in date‑range
  SELECT
    user_pseudo_id,
    /* pull ga_session_id out of the event_params array              */
    ARRAY(
      SELECT ep.value.int_value
      FROM   UNNEST(event_params) ep
      WHERE  ep.key = 'ga_session_id'
    )[SAFE_OFFSET(0)]               AS ga_session_id,
    ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
        _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
),

session_revenue AS (              -- 2. revenue per user × session
  SELECT
    user_pseudo_id,
    ga_session_id,
    SUM(purchase_revenue_usd) AS session_purchase_revenue_usd
  FROM purchase_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
),

user_stats AS (                   -- 3. metrics per user
  SELECT
    user_pseudo_id,
    COUNT(*)                               AS purchase_sessions,
    AVG(session_purchase_revenue_usd)      AS avg_purchase_revenue_usd_per_session
  FROM session_revenue
  GROUP BY user_pseudo_id
)

SELECT
  user_pseudo_id,
  avg_purchase_revenue_usd_per_session
FROM user_stats
WHERE purchase_sessions > 1               -- users with >1 purchase session
ORDER BY avg_purchase_revenue_usd_per_session DESC;