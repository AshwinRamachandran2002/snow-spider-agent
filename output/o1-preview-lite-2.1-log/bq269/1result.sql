WITH
  session_data AS (
    SELECT
      SUBSTR(date, 1, 6) AS month,
      fullVisitorId,
      IFNULL(totals.pageviews, 0) AS pageviews,
      CASE
        WHEN totals.transactions > 0 THEN 'Purchase'
        ELSE 'Non-Purchase'
      END AS event_type
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE
      _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
  ),
  visitor_pageviews AS (
    SELECT
      month,
      event_type,
      fullVisitorId,
      SUM(pageviews) AS total_pageviews
    FROM
      session_data
    GROUP BY
      month, event_type, fullVisitorId
  )
SELECT
  CONCAT(
    CASE SUBSTR(month, 5, 2)
      WHEN '06' THEN 'June'
      WHEN '07' THEN 'July'
    END,
    '-',
    SUBSTR(month, 1, 4)
  ) AS Month,
  ROUND(AVG(CASE WHEN event_type = 'Non-Purchase' THEN total_pageviews END), 4) AS Average_Pageviews_Per_Visitor_Non_Purchase,
  ROUND(AVG(CASE WHEN event_type = 'Purchase' THEN total_pageviews END), 4) AS Average_Pageviews_Per_Visitor_Purchase
FROM
  visitor_pageviews
GROUP BY
  Month
ORDER BY
  Month;