WITH sessions AS (
  SELECT
    SUBSTR(`date`, 1, 6)                                                  AS month,        -- YYYYMM
    `fullVisitorId`                                                       AS visitor_id,
    CASE WHEN totals.transactions >= 1 THEN 'purchase' ELSE 'non_purchase' END AS cls,     -- classification
    totals.pageviews                                                      AS pageviews
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'   -- June-July 2017 tables
    AND totals.pageviews IS NOT NULL                      -- keep only sessions with pageviews
),

visitor_month AS (
  -- sum pageviews per visitor-month-class
  SELECT
    month,
    visitor_id,
    cls,
    SUM(pageviews) AS visitor_pv
  FROM sessions
  GROUP BY month, visitor_id, cls
)

-- average pageviews per visitor for each class, side-by-side
SELECT
  month,
  AVG(IF(cls = 'purchase',     visitor_pv, NULL)) AS avg_pageviews_purchase,
  AVG(IF(cls = 'non_purchase', visitor_pv, NULL)) AS avg_pageviews_non_purchase
FROM visitor_month
GROUP BY month
ORDER BY month;