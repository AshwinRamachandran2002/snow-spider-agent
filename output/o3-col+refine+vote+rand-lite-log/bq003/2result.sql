/*  Average page-views per visitor by month (Apr-Jul 2017)  
    split into purchase vs non-purchase sessions                          */

WITH sessions AS (
  SELECT
    -- month label like 2017-04, 2017-05 …
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', `date`))          AS month,
    fullVisitorId,
    totals.pageviews                                            AS pageviews,
    totals.transactions                                         AS transactions,
    hits
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  -- take only daily tables from 1-Apr-2017 through 31-Jul-2017
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),

/* classify every session */
classified AS (
  SELECT
    month,
    fullVisitorId,
    pageviews,
    CASE
      WHEN transactions >= 1
           AND (SELECT COUNTIF(p.productRevenue IS NOT NULL)
                  FROM UNNEST(hits) AS h
                  CROSS JOIN UNNEST(h.product) AS p) > 0
        THEN 'purchase'
      ELSE 'non-purchase'
    END                                                        AS session_type
  FROM sessions
),

/* aggregate to visitor-level page-views within each month & class */
visitor_month AS (
  SELECT
    month,
    session_type,
    fullVisitorId,
    SUM(pageviews)                                             AS pageviews_per_visitor
  FROM classified
  GROUP BY month, session_type, fullVisitorId
)

SELECT
  month,
  session_type,
  ROUND(AVG(pageviews_per_visitor), 4)                         AS avg_pageviews_per_visitor
FROM visitor_month
GROUP BY month, session_type
ORDER BY month, session_type;