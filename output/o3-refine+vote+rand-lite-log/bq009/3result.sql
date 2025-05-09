WITH sessions AS (
  -- 2017 sessions with revenue and traffic source
  SELECT
    trafficSource.source                                AS source,
    IFNULL(totals.totalTransactionRevenue,0)/1e12       AS revenue_million, -- convert to millions
    SUBSTR(date,1,6)                                    AS ym               -- YYYYMM
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20171231'
),
source_totals AS (
  -- yearly revenue per traffic source
  SELECT
    source,
    SUM(revenue_million) AS total_revenue_million
  FROM sessions
  GROUP BY source
),
top_source AS (
  -- traffic source with the highest total revenue
  SELECT source
  FROM source_totals
  ORDER BY total_revenue_million DESC
  LIMIT 1
),
top_source_sessions AS (
  -- only sessions coming from the top traffic source
  SELECT *
  FROM sessions
  WHERE source = (SELECT source FROM top_source)
),
months AS (
  -- all months in 2017
  SELECT FORMAT_DATE('%Y%m', DATE_ADD(DATE '2017-01-01', INTERVAL m MONTH)) AS ym
  FROM UNNEST(GENERATE_ARRAY(0,11)) AS m
),
monthly_revenue AS (
  -- monthly revenue for the top traffic source (zero for months with no revenue)
  SELECT
    m.ym,
    IFNULL(SUM(ts.revenue_million),0) AS monthly_revenue_million
  FROM months m
  LEFT JOIN top_source_sessions ts
         ON ts.ym = m.ym
  GROUP BY m.ym
)
SELECT
  (SELECT source FROM top_source)                                   AS traffic_source,
  ROUND(MAX(monthly_revenue_million) -
        MIN(monthly_revenue_million), 2)                            AS diff_in_millions
FROM monthly_revenue;