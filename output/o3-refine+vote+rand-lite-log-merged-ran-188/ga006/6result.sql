/*  Average purchase revenue (USD) per session
    for users that had more than one purchase session
    between 1‑Nov‑2020 and 30‑Nov‑2020                    */

WITH purchases AS (
    SELECT
        user_pseudo_id,
        -- extract GA session id from the repeated event_params record
        (
          SELECT ep.value.int_value
          FROM UNNEST(event_params) AS ep
          WHERE ep.key = 'ga_session_id'
          LIMIT 1
        ) AS ga_session_id,
        ecommerce.purchase_revenue_in_usd AS revenue_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
      AND event_name = 'purchase'
      AND ecommerce.purchase_revenue_in_usd IS NOT NULL
),
/* consolidate to one row per user‑session              */
session_revenue AS (
    SELECT
        user_pseudo_id,
        ga_session_id,
        SUM(revenue_usd) AS session_revenue_usd
    FROM purchases
    WHERE ga_session_id IS NOT NULL
    GROUP BY user_pseudo_id, ga_session_id
),
/* compute user‑level stats                              */
user_stats AS (
    SELECT
        user_pseudo_id,
        COUNT(*)                              AS purchase_sessions,
        AVG(session_revenue_usd)              AS avg_purchase_revenue_usd_per_session
    FROM session_revenue
    GROUP BY user_pseudo_id
)
SELECT
    user_pseudo_id,
    avg_purchase_revenue_usd_per_session
FROM user_stats
WHERE purchase_sessions > 1;