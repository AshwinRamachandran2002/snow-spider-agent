-- Average purchase‑revenue per session (USD) for users with >1 purchase session
WITH session_revenue AS (
  -- one row per (user, session) with the sum of purchase revenue in that session
  SELECT
    e.user_pseudo_id,
    ep.value.int_value                AS ga_session_id,
    SUM(e.ecommerce.purchase_revenue_in_usd) AS session_revenue_usd
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
    CROSS JOIN UNNEST(e.event_params) AS ep
  WHERE
        _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'     -- 1–30 Nov 2020
    AND e.event_name = 'purchase'
    AND e.ecommerce.purchase_revenue_in_usd IS NOT NULL
    AND ep.key = 'ga_session_id'
  GROUP BY
    e.user_pseudo_id,
    ga_session_id
),
multi_purchase_users AS (
  -- keep only users who have more than one purchase session
  SELECT
    user_pseudo_id
  FROM
    session_revenue
  GROUP BY
    user_pseudo_id
  HAVING
    COUNT(*) > 1
)
SELECT
  sr.user_pseudo_id,
  ROUND(AVG(sr.session_revenue_usd), 4) AS avg_purchase_revenue_per_session_usd
FROM
  session_revenue AS sr
  JOIN multi_purchase_users AS mu
    ON sr.user_pseudo_id = mu.user_pseudo_id
GROUP BY
  sr.user_pseudo_id;