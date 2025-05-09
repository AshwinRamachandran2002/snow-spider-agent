/*  Average page-views per visitor for purchase vs. non-purchase sessions
    between 01-Apr-2017 and 31-Jul-2017                              */
WITH session_level AS (
  SELECT
    -- month of the session
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS year_month,
    fullVisitorId,
    -- classify each session
    CASE
      WHEN totals.transactions >= 1
           AND EXISTS (
             SELECT 1
             FROM UNNEST(hits) h, UNNEST(h.product) p
             WHERE p.productRevenue IS NOT NULL
           )
        THEN 'purchase'
      ELSE 'non_purchase'
    END                                                           AS session_type,
    IFNULL(totals.pageviews, 0) AS pageviews
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),
visitor_month AS (   -- aggregate to visitor-month level
  SELECT
    year_month,
    fullVisitorId,
    session_type,
    SUM(pageviews) AS visitor_pageviews
  FROM session_level
  GROUP BY year_month, fullVisitorId, session_type
)
SELECT
  year_month,
  session_type,
  AVG(visitor_pageviews) AS avg_pageviews_per_visitor
FROM visitor_month
GROUP BY year_month, session_type
ORDER BY year_month, session_type;