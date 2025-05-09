SELECT
  Month,
  AVG(Pageviews_Non_Purchase) AS Average_Pageviews_Per_Visitor_Non_Purchase,
  AVG(Pageviews_Purchase) AS Average_Pageviews_Per_Visitor_Purchase
FROM (
  SELECT
    fullVisitorId,
    FORMAT_DATE('%B-%Y', PARSE_DATE('%Y%m%d', `date`)) AS Month,
    SUM(IF(totals.transactions IS NULL OR totals.transactions = 0, totals.pageviews, 0)) AS Pageviews_Non_Purchase,
    SUM(IF(totals.transactions > 0, totals.pageviews, 0)) AS Pageviews_Purchase
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
  GROUP BY
    fullVisitorId,
    Month
)
GROUP BY
  Month
ORDER BY
  PARSE_DATE('%B-%Y', Month);