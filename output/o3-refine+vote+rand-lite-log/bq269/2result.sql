-- Average pageviews‑per‑visitor for purchase vs. non‑purchase sessions  
-- June‑July 2017 (Google Analytics sample)

WITH sessions AS (
  SELECT
    fullVisitorId,
    SUBSTR(date, 1, 6)                           AS month,                 -- ‘201706’, ‘201707’
    totals.pageviews                             AS pageviews,
    CASE
      WHEN IFNULL(totals.transactions, 0) > 0
           THEN 'purchase'
      ELSE 'non_purchase'
    END                                          AS session_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'       -- 1 Jun – 31 Jul 2017
    AND totals.pageviews IS NOT NULL                          -- keep only sessions with pageviews
),

visitor_month AS (        -- pageviews summed per visitor, month & classification
  SELECT
    month,
    fullVisitorId,
    session_type,
    SUM(pageviews) AS sum_pageviews
  FROM sessions
  GROUP BY month, fullVisitorId, session_type
)

SELECT
  month,
  ROUND(AVG(IF(session_type = 'purchase'     , sum_pageviews, NULL)), 4) AS avg_pageviews_purchase,
  ROUND(AVG(IF(session_type = 'non_purchase' , sum_pageviews, NULL)), 4) AS avg_pageviews_non_purchase
FROM visitor_month
GROUP BY month
ORDER BY month;