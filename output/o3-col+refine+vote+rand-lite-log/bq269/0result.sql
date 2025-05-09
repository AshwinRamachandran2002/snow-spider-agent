-- Average pageviews per visitor for purchase vs. non-purchase sessions
-- between 2017-06-01 and 2017-07-31
SELECT
  month,
  AVG(IF(session_type = 'purchase',     visitor_pageviews, NULL)) AS avg_pageviews_purchase,
  AVG(IF(session_type = 'non_purchase', visitor_pageviews, NULL)) AS avg_pageviews_non_purchase
FROM (
  -- Aggregate each visitor’s pageviews by month and session classification
  SELECT
    SUBSTR(date, 1, 6) AS month,                         -- e.g. 201706
    fullVisitorId,
    CASE
      WHEN totals.transactions > 0 THEN 'purchase'
      ELSE 'non_purchase'
    END AS session_type,
    SUM(totals.pageviews) AS visitor_pageviews
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE date BETWEEN '20170601' AND '20170731'           -- limit to the date range
    AND totals.pageviews IS NOT NULL                     -- only sessions with pageviews
  GROUP BY month, fullVisitorId, session_type
)
GROUP BY month
ORDER BY month;