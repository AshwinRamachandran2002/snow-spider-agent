-- traffic source with the highest total transaction revenue in 2017
-- and the gap (in millions) between its highest‑revenue month and lowest‑revenue month
WITH sessions_2017 AS (     -- all 2017 sessions
  SELECT
    trafficSource.source                           AS source,
    totals.totalTransactionRevenue                 AS revenue,
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
),
source_totals AS (          -- total revenue per source for the year
  SELECT
    source,
    SUM(COALESCE(revenue, 0)) AS total_rev
  FROM sessions_2017
  GROUP BY source
),
top_source AS (             -- the single largest‑revenue source
  SELECT source
  FROM source_totals
  ORDER BY total_rev DESC
  LIMIT 1
),
monthly_rev AS (            -- monthly revenue for that source
  SELECT
    month,
    SUM(COALESCE(revenue, 0)) AS month_rev
  FROM sessions_2017
  WHERE source = (SELECT source FROM top_source)
  GROUP BY month
),
extremes AS (               -- highest and lowest month totals
  SELECT
    MAX(month_rev) AS max_rev,
    MIN(month_rev) AS min_rev
  FROM monthly_rev
)
SELECT
  (SELECT source FROM top_source)                                         AS traffic_source,
  ROUND((max_rev - min_rev) / 1e6, 2)                                     AS revenue_difference_millions
FROM extremes;