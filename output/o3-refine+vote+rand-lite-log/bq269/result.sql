-- Average pageviews per visitor for purchase vs. non‑purchase sessions
-- between 2017‑06‑01 and 2017‑07‑31
WITH sessions AS (
  SELECT
    PARSE_DATE('%Y%m%d', date)                          AS session_date,
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date))    AS month,
    fullVisitorId,
    totals.pageviews                                    AS pageviews,
    CASE
      WHEN totals.transactions IS NOT NULL
           AND totals.transactions > 0                 THEN 'purchase'
      ELSE 'non_purchase'
    END                                                 AS classification
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'    -- tables 2017‑06‑01 .. 2017‑07‑31
    AND totals.pageviews IS NOT NULL                       -- only sessions with pageviews
),

visitor_monthly AS (
  -- sum pageviews per visitor per month & classification
  SELECT
    month,
    classification,
    fullVisitorId,
    SUM(pageviews) AS visitor_pageviews
  FROM sessions
  GROUP BY month, classification, fullVisitorId
)

SELECT
  month,
  AVG(IF(classification = 'purchase',     visitor_pageviews, NULL)) AS avg_pageviews_purchase,
  AVG(IF(classification = 'non_purchase', visitor_pageviews, NULL)) AS avg_pageviews_non_purchase
FROM visitor_monthly
GROUP BY month
ORDER BY month;