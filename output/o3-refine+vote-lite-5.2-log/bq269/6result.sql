/* Average pageviews per visitor (Jun–Jul 2017)
   split into “purchase” and “non_purchase” session groups          */

WITH filtered_sessions AS (
  SELECT
    PARSE_DATE('%Y%m%d', `date`) AS session_date,
    fullVisitorId,
    totals.pageviews            AS pageviews,
    totals.transactions         AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
        _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'   -- 1 Jun – 31 Jul 2017
    AND totals.pageviews IS NOT NULL                      -- keep sessions that have pageviews
),

classified_sessions AS (
  SELECT
    FORMAT_DATE('%Y-%m', session_date)                                   AS month,   -- e.g. 2017-06
    fullVisitorId,
    pageviews,
    IF(COALESCE(transactions, 0) > 0, 'purchase', 'non_purchase')        AS session_type
  FROM filtered_sessions
),

visitor_monthly AS (
  -- total pageviews a visitor generated in the month per class
  SELECT
    month,
    fullVisitorId,
    session_type,
    SUM(pageviews) AS visitor_pageviews
  FROM classified_sessions
  GROUP BY month, fullVisitorId, session_type
),

avg_pageviews_cte AS (
  -- average of those visitor‑level sums per month & class
  SELECT
    month,
    session_type,
    AVG(visitor_pageviews) AS avg_views
  FROM visitor_monthly
  GROUP BY month, session_type
)

-- present purchase & non‑purchase averages side by side
SELECT
  month,
  COALESCE(MAX(IF(session_type = 'purchase',     avg_views, NULL)), 0) AS purchase_avg_pageviews,
  COALESCE(MAX(IF(session_type = 'non_purchase', avg_views, NULL)), 0) AS non_purchase_avg_pageviews
FROM avg_pageviews_cte
GROUP BY month
ORDER BY month;