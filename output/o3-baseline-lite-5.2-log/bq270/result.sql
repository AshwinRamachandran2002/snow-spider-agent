WITH product_events AS (
  SELECT
    -- convert the table suffix (yyyymmdd) into a month label
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS month,
    CAST(hits.eCommerceAction.action_type AS INT64)            AS action_type
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits)   AS hits,
    UNNEST(hits.product) AS prod
  WHERE
        -- restrict to January‑March 2017 tables
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    -- ignore product impressions (they belong to list views, not detail pages)
    AND (prod.isImpression IS NULL OR prod.isImpression = FALSE)
)

SELECT
  month,
  100 * SAFE_DIVIDE(
        SUM(CASE WHEN action_type = 3 THEN 1 ELSE 0 END),
        SUM(CASE WHEN action_type = 2 THEN 1 ELSE 0 END)
      ) AS add_to_cart_conversion_pct,
  100 * SAFE_DIVIDE(
        SUM(CASE WHEN action_type = 6 THEN 1 ELSE 0 END),
        SUM(CASE WHEN action_type = 2 THEN 1 ELSE 0 END)
      ) AS purchase_conversion_pct
FROM
  product_events
GROUP BY
  month
ORDER BY
  month;