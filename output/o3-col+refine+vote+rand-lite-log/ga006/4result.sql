-- Average purchase revenue (USD) per session for users with >1 purchase session
WITH session_revenue AS (
  SELECT
    user_pseudo_id,
    ep.value.int_value                             AS ga_session_id,
    SUM(ecommerce.purchase_revenue_in_usd)         AS session_revenue_usd
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(event_params) AS ep
  WHERE
        _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
    AND ep.key = 'ga_session_id'
  GROUP BY
    user_pseudo_id,
    ga_session_id
)

SELECT
  user_pseudo_id,
  COUNT(*)                       AS purchase_sessions,
  AVG(session_revenue_usd)       AS avg_purchase_rev_usd_per_session
FROM
  session_revenue
GROUP BY
  user_pseudo_id
HAVING
  purchase_sessions > 1
ORDER BY
  avg_purchase_rev_usd_per_session DESC;