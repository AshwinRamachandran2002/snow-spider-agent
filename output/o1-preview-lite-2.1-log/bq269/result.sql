WITH session_data AS (
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', `date`)) AS month,
    fullVisitorId,
    totals.pageviews AS pageviews_per_session,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM UNNEST(hits) AS h
        WHERE h.eCommerceAction.action_type = '6'
      ) THEN 'Purchase'
      ELSE 'Non-Purchase'
    END AS event_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
),

visitor_data AS (
  SELECT
    month,
    fullVisitorId,
    event_type,
    SUM(IFNULL(pageviews_per_session, 0)) AS pageviews_per_visitor
  FROM session_data
  GROUP BY month, fullVisitorId, event_type
)

SELECT
  CONCAT(
    CASE month
      WHEN 6 THEN 'June-2017'
      WHEN 7 THEN 'July-2017'
    END
  ) AS Month,
  ROUND(AVG(IF(event_type = 'Non-Purchase', pageviews_per_visitor, NULL)), 4) AS Average_Pageviews_Per_Visitor_Non_Purchase,
  ROUND(AVG(IF(event_type = 'Purchase', pageviews_per_visitor, NULL)), 4) AS Average_Pageviews_Per_Visitor_Purchase
FROM visitor_data
GROUP BY Month
ORDER BY Month;