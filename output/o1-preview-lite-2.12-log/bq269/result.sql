WITH session_data AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date) AS session_date,
    SAFE_CAST(totals.pageviews AS INT64) AS pageviews,
    SAFE_CAST(totals.transactions AS INT64) AS transactions,
    CASE
      WHEN SUBSTR(date, 1, 6) = '201706' THEN 'June 2017'
      WHEN SUBSTR(date, 1, 6) = '201707' THEN 'July 2017'
    END AS Month,
    CASE
      WHEN SAFE_CAST(totals.transactions AS INT64) >= 1 THEN 'purchase'
      ELSE 'non_purchase'
    END AS session_type
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
    AND totals.pageviews IS NOT NULL
    AND (SUBSTR(date,1,6) = '201706' OR SUBSTR(date,1,6) = '201707')
),
visitor_data AS (
  SELECT
    fullVisitorId,
    Month,
    SUM(CASE WHEN session_type = 'purchase' THEN pageviews ELSE 0 END) AS total_purchase_pageviews,
    SUM(CASE WHEN session_type = 'non_purchase' THEN pageviews ELSE 0 END) AS total_non_purchase_pageviews
  FROM
    session_data
  WHERE
    Month IS NOT NULL
  GROUP BY
    fullVisitorId, Month
),
purchase_stats AS (
  SELECT
    Month,
    AVG(total_purchase_pageviews) AS Purchase_Average_Pageviews
  FROM
    visitor_data
  WHERE
    total_purchase_pageviews > 0
  GROUP BY
    Month
),
non_purchase_stats AS (
  SELECT
    Month,
    AVG(total_non_purchase_pageviews) AS Non_Purchase_Average_Pageviews
  FROM
    visitor_data
  WHERE
    total_non_purchase_pageviews > 0
  GROUP BY
    Month
)
SELECT
  p.Month,
  ROUND(p.Purchase_Average_Pageviews, 4) AS Purchase_Average_Pageviews,
  ROUND(n.Non_Purchase_Average_Pageviews, 4) AS Non_Purchase_Average_Pageviews
FROM
  purchase_stats p
JOIN
  non_purchase_stats n USING (Month)
ORDER BY
  CASE p.Month
    WHEN 'June 2017' THEN 1
    WHEN 'July 2017' THEN 2
  END