-- traffic source with the highest 2017 revenue and the gap between its
-- highest- and lowest-grossing months (in millions of currency units)
WITH top_source AS (             -- 1) winner by full-year revenue
  SELECT
    trafficSource.source                    AS source,
    SUM(IFNULL(totals.totalTransactionRevenue,0)) AS rev_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  GROUP BY source
  ORDER BY rev_micro DESC
  LIMIT 1
),
monthly_revenue AS (             -- 2) month-level revenue for every source
  SELECT
    trafficSource.source                    AS source,
    SUBSTR(_TABLE_SUFFIX,1,6)               AS yr_month,      -- e.g. 201701
    SUM(IFNULL(totals.totalTransactionRevenue,0)) AS month_rev_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  GROUP BY source, yr_month
)
SELECT
  t.source AS traffic_source,                                    -- winner
  ROUND( (MAX(m.month_rev_micro) - MIN(m.month_rev_micro))       -- gap
         / 1e12 ,                                                -- to millions
         2)        AS diff_millions
FROM top_source     AS t
JOIN monthly_revenue AS m
ON  m.source = t.source
GROUP BY t.source;