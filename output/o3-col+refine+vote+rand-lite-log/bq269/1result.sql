WITH per_session AS (
  SELECT
    SUBSTR(`date`,1,6) AS month,              -- YYYYMM
    `fullVisitorId`,
    totals.pageviews                           AS pageviews,
    CASE
      WHEN totals.transactions IS NOT NULL
           AND totals.transactions > 0         THEN 'purchase'
      ELSE 'non_purchase'
    END                                        AS classification
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
    AND totals.pageviews IS NOT NULL           -- keep only sessions with pageviews
),
visitor_month AS (
  -- total pageviews each visitor generated in the month for each classification
  SELECT
    month,
    fullVisitorId,
    classification,
    SUM(pageviews) AS visitor_pageviews
  FROM per_session
  GROUP BY month, fullVisitorId, classification
)

SELECT
  month,
  ROUND(AVG(CASE WHEN classification = 'purchase'      THEN visitor_pageviews END), 4) AS avg_pageviews_purchase,
  ROUND(AVG(CASE WHEN classification = 'non_purchase'  THEN visitor_pageviews END), 4) AS avg_pageviews_non_purchase
FROM visitor_month
GROUP BY month
ORDER BY month;