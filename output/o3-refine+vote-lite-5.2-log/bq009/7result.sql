WITH source_total AS (
  -- 1) total 2017 revenue (in micros) for each traffic source
  SELECT
    trafficSource.source                               AS source,
    SUM(IFNULL(totals.totalTransactionRevenue,0))      AS revenue_micros
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  GROUP BY
    source
),
top_source AS (
  -- 2) traffic source with the highest revenue
  SELECT
    source
  FROM
    source_total
  ORDER BY
    revenue_micros DESC
  LIMIT 1
),
monthly_rev AS (
  -- 3) monthly revenue (in micros) for every source
  SELECT
    trafficSource.source                               AS source,
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date))    AS yr_month,
    SUM(IFNULL(totals.totalTransactionRevenue,0))      AS month_rev_micros
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  GROUP BY
    source, yr_month
)

-- 4) result for the top‑revenue source
SELECT
  ts.source                                                        AS traffic_source,
  ROUND( (MAX(mr.month_rev_micros) - MIN(mr.month_rev_micros))
         / 1e12,                                                   -- convert micros → millions
         2)                                                        AS diff_in_millions
FROM
  monthly_rev mr
JOIN
  top_source ts
ON
  mr.source = ts.source
GROUP BY
  ts.source;