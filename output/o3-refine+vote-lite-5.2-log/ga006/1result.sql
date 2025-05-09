/* Average purchase‑revenue (USD) per session for users
   who recorded purchases in more than one session
   between 1‑Nov‑2020 and 30‑Nov‑2020                       */

WITH purchase_events AS (
  SELECT
    user_pseudo_id,
    /* pull the GA4 session id stored in event_params */
    (
      SELECT ep.value.int_value
      FROM   UNNEST(event_params) ep
      WHERE  ep.key = 'ga_session_id'
      LIMIT  1
    )                                              AS ga_session_id,
    ecommerce.purchase_revenue_in_usd              AS revenue_usd
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
        _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'   -- Nov‑2020 tables
    AND event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
),

/* total purchase revenue per (user, session) */
session_revenue AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    SUM(revenue_usd) AS session_revenue_usd
  FROM purchase_events
  GROUP BY user_pseudo_id, ga_session_id
)

SELECT
  user_pseudo_id,
  AVG(session_revenue_usd) AS avg_purchase_revenue_usd_per_session
FROM session_revenue
GROUP BY user_pseudo_id
HAVING COUNT(ga_session_id) > 1         -- users with >1 purchase session
ORDER BY avg_purchase_revenue_usd_per_session DESC;