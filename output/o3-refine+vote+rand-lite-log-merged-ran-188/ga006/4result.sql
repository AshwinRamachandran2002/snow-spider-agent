/*  Average purchase revenue (USD) per session for users who made
    more than one purchase session between 1–30 Nov 2020            */
WITH purchase_events AS (
  SELECT
    user_pseudo_id,
    /* extract ga_session_id from the repeated event_params array   */
    (
      SELECT ep.value.int_value
      FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'ga_session_id'
      LIMIT 1
    )                                               AS ga_session_id,
    ecommerce.purchase_revenue_in_usd               AS purchase_revenue_usd
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE
        event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
    AND event_date BETWEEN '20201101' AND '20201130'
),

/* total purchase revenue per user‑session                                   */
session_revenue AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    SUM(purchase_revenue_usd) AS session_purchase_revenue_usd
  FROM purchase_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
),

/* average revenue per session & session count per user                      */
user_avg AS (
  SELECT
    user_pseudo_id,
    AVG(session_purchase_revenue_usd)  AS avg_purchase_revenue_usd_per_session,
    COUNT(*)                           AS purchase_sessions
  FROM session_revenue
  GROUP BY user_pseudo_id
)

SELECT
  user_pseudo_id,
  ROUND(avg_purchase_revenue_usd_per_session, 4) AS avg_purchase_revenue_usd_per_session
FROM user_avg
WHERE purchase_sessions > 1      -- keep users with >1 purchase session
ORDER BY user_pseudo_id;