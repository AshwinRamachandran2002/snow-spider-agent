WITH sessions AS (
  SELECT 
    FORMAT_DATE('%b-%Y', PARSE_DATE('%Y%m%d', date)) AS Month,
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date)) AS MonthNumber,
    fullVisitorId,
    t.totals.pageviews AS pageviews,
    t.totals.transactions AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),
purchase_sessions AS (
  SELECT Month, MonthNumber, fullVisitorId, SUM(pageviews) AS total_pageviews
  FROM sessions
  WHERE transactions > 0
  GROUP BY Month, MonthNumber, fullVisitorId
),
nonpurchase_sessions AS (
  SELECT Month, MonthNumber, fullVisitorId, SUM(pageviews) AS total_pageviews
  FROM sessions
  WHERE transactions IS NULL OR transactions = 0
  GROUP BY Month, MonthNumber, fullVisitorId
),
purchase_stats AS (
  SELECT Month, MonthNumber, AVG(total_pageviews) AS Average_Pageviews_per_Visitor_Purchase_Sessions
  FROM purchase_sessions
  GROUP BY Month, MonthNumber
),
nonpurchase_stats AS (
  SELECT Month, MonthNumber, AVG(total_pageviews) AS Average_Pageviews_per_Visitor_NonPurchase_Sessions
  FROM nonpurchase_sessions
  GROUP BY Month, MonthNumber
)
SELECT 
  COALESCE(p.Month, np.Month) AS Month,
  ROUND(p.Average_Pageviews_per_Visitor_Purchase_Sessions, 4) AS Average_Pageviews_per_Visitor_Purchase_Sessions,
  ROUND(np.Average_Pageviews_per_Visitor_NonPurchase_Sessions, 4) AS Average_Pageviews_per_Visitor_NonPurchase_Sessions
FROM purchase_stats p
FULL OUTER JOIN nonpurchase_stats np ON p.Month = np.Month
ORDER BY COALESCE(p.MonthNumber, np.MonthNumber)