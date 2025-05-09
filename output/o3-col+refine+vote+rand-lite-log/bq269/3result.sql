-- Average monthly pageviews per visitor (purchase vs. non-purchase) for Jun–Jul 2017
WITH visitor_month AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', `date`)) AS yr_month,
    fullVisitorId,
    CASE
      WHEN totals.transactions IS NOT NULL AND totals.transactions > 0
      THEN 'purchase'
      ELSE 'non_purchase'
    END                                                       AS session_type,
    SUM(totals.pageviews)                                     AS monthly_pageviews
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
    AND totals.pageviews IS NOT NULL        -- keep sessions with pageviews
  GROUP BY yr_month, fullVisitorId, session_type
)

SELECT
  yr_month,
  AVG(IF(session_type = 'purchase',     monthly_pageviews, NULL)) AS avg_pageviews_purchase,
  AVG(IF(session_type = 'non_purchase', monthly_pageviews, NULL)) AS avg_pageviews_non_purchase
FROM visitor_month
GROUP BY yr_month
ORDER BY yr_month;