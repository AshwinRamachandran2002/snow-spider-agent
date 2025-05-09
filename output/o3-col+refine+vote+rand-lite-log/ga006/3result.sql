/* Average purchase-session revenue for users with >1 purchase session
   during Nov-01‒30, 2020                                           */

WITH purchase_events AS (   -- individual purchase events
  SELECT
    user_pseudo_id,
    -- pull the GA session id from the nested event_params array
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) AS ep
     WHERE ep.key = 'ga_session_id') AS ga_session_id,
    ecommerce.purchase_revenue_in_usd AS purchase_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
    -- keep only tables for 1-30 Nov 2020
    AND CAST(_TABLE_SUFFIX AS INT64) BETWEEN 1 AND 30
),

session_revenue AS (        -- revenue aggregated to (user, session)
  SELECT
    user_pseudo_id,
    ga_session_id,
    SUM(purchase_usd) AS session_revenue_usd
  FROM purchase_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
)

SELECT
  user_pseudo_id,
  AVG(session_revenue_usd) AS avg_purchase_revenue_usd_per_session
FROM session_revenue
GROUP BY user_pseudo_id
HAVING COUNT(*) > 1      -- only users with >1 distinct purchase session
ORDER BY avg_purchase_revenue_usd_per_session DESC;