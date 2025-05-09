-- Average monthly pageviews per visitor for purchase vs. non‑purchase sessions
WITH visitor_monthly AS (
  SELECT
    SUBSTR(date, 1, 6) AS yyyymm,                -- e.g. 201706
    fullVisitorId,
    CASE
      WHEN totals.transactions IS NOT NULL
           AND totals.transactions > 0 THEN 'purchase'
      ELSE 'non_purchase'
    END AS session_type,
    SUM(totals.pageviews) AS visitor_month_pageviews
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'  -- June‑July 2017 tables
    AND totals.pageviews IS NOT NULL                     -- only sessions with pageviews
  GROUP BY yyyymm, fullVisitorId, session_type
)

SELECT
  yyyymm,
  AVG(IF(session_type = 'purchase',     visitor_month_pageviews, NULL))
      AS avg_pageviews_purchase,
  AVG(IF(session_type = 'non_purchase', visitor_month_pageviews, NULL))
      AS avg_pageviews_non_purchase
FROM visitor_monthly
GROUP BY yyyymm
ORDER BY yyyymm;