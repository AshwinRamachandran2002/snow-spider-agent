WITH sessions AS (
  SELECT
    fullVisitorId,
    totals.pageviews AS pageviews,
    totals.transactions,
    PARSE_DATE('%Y%m%d', date) AS date_parsed,
    CASE
      WHEN totals.transactions >= 1 THEN 'purchase'
      ELSE 'non_purchase'
    END AS session_type
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
    AND totals.pageviews IS NOT NULL
),
visitor_pageviews AS (
  SELECT
    FORMAT_DATE('%B %Y', date_parsed) AS month,
    fullVisitorId,
    session_type,
    SUM(pageviews) AS total_pageviews
  FROM
    sessions
  GROUP BY
    month, fullVisitorId, session_type
)
SELECT
  month,
  ROUND(AVG(CASE WHEN session_type = 'purchase' THEN total_pageviews END), 4) AS Purchase_Average_Pageviews,
  ROUND(AVG(CASE WHEN session_type = 'non_purchase' THEN total_pageviews END), 4) AS Non_Purchase_Average_Pageviews
FROM
  visitor_pageviews
GROUP BY
  month
ORDER BY
  month;