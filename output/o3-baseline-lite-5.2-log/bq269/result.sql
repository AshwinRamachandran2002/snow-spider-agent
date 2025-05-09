/*  Average pageviews per visitor for purchase / non‑purchase sessions
    (sessions dated 2017‑06‑01 – 2017‑07‑31, pageviews not null)            */

WITH sessions AS (
  SELECT
    /* month in YYYY‑MM format */
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', `date`))                AS month,
    fullVisitorId,
    /* classify each session */
    CASE
      WHEN totals.transactions IS NOT NULL
           AND totals.transactions > 0                                 THEN 'purchase'
      ELSE 'non_purchase'
    END                                                               AS session_type,
    totals.pageviews                                                  AS pageviews
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  /* pick only the needed two months’ tables  */
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
        AND totals.pageviews IS NOT NULL
),

/* sum pageviews per visitor, per month, per classification */
visitor_monthly AS (
  SELECT
    month,
    session_type,
    fullVisitorId,
    SUM(pageviews) AS total_pageviews
  FROM sessions
  GROUP BY month, session_type, fullVisitorId
)

/* average those visitor‑level sums for each month & class */
SELECT
  month,
  ROUND(AVG(IF(session_type = 'purchase'     , total_pageviews, NULL)), 4)
      AS avg_pageviews_purchase,
  ROUND(AVG(IF(session_type = 'non_purchase' , total_pageviews, NULL)), 4)
      AS avg_pageviews_non_purchase
FROM visitor_monthly
GROUP BY month
ORDER BY month;