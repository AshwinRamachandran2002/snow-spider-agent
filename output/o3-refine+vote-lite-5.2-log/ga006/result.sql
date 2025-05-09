-- Average purchase revenue (USD) per session, per user, for users having
-- more than one purchase‑session between 1–30 Nov 2020
WITH purchase_events AS (
  SELECT
    user_pseudo_id,
    -- pull the GA4 session id stored in event_params
    (
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
      LIMIT 1
    )                                        AS ga_session_id,
    ecommerce.purchase_revenue_in_usd        AS revenue_usd
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'        -- Nov‑2020 tables
    AND event_name = 'purchase'                            -- purchase events only
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL      -- keep only monetised events
),
/* revenue aggregated at session level */
session_revenue AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    SUM(revenue_usd) AS session_revenue_usd
  FROM purchase_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
),
/* stats per user */
user_stats AS (
  SELECT
    user_pseudo_id,
    AVG(session_revenue_usd) AS avg_purchase_revenue_usd_per_session,
    COUNT(*)                 AS purchase_sessions
  FROM session_revenue
  GROUP BY user_pseudo_id
)
SELECT
  user_pseudo_id,
  ROUND(avg_purchase_revenue_usd_per_session, 4) AS avg_purchase_revenue_usd_per_session
FROM user_stats
WHERE purchase_sessions > 1                       -- users with >1 purchase session
ORDER BY user_pseudo_id;