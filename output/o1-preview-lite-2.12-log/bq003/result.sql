WITH session_classification AS (
  SELECT
    PARSE_DATE('%Y%m%d', date) AS session_date,
    EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', date)) AS year,
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date)) AS month,
    fullVisitorId,
    totals.pageviews AS session_pageviews,
    CASE
      WHEN totals.transactions >= 1 AND EXISTS(
        SELECT 1 FROM UNNEST(hits) AS h
        WHERE EXISTS(
          SELECT 1 FROM UNNEST(h.product) AS p
          WHERE p.productRevenue IS NOT NULL
        )
      ) THEN 'Purchase'
      WHEN totals.transactions IS NULL AND NOT EXISTS(
        SELECT 1 FROM UNNEST(hits) AS h
        WHERE EXISTS(
          SELECT 1 FROM UNNEST(h.product) AS p
          WHERE p.productRevenue IS NOT NULL
        )
      ) THEN 'Non-Purchase'
      ELSE 'Other'
    END AS session_type
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
)

SELECT
  CONCAT(
    CASE month
      WHEN 1 THEN 'January'
      WHEN 2 THEN 'February'
      WHEN 3 THEN 'March'
      WHEN 4 THEN 'April'
      WHEN 5 THEN 'May'
      WHEN 6 THEN 'June'
      WHEN 7 THEN 'July'
      WHEN 8 THEN 'August'
      WHEN 9 THEN 'September'
      WHEN 10 THEN 'October'
      WHEN 11 THEN 'November'
      WHEN 12 THEN 'December'
    END,
    '-', CAST(year AS STRING)
  ) AS Month,
  session_type AS `Group`,
  ROUND(AVG(total_pageviews_per_visitor), 4) AS Average_Pageviews_Per_Visitor
FROM (
  SELECT
    fullVisitorId,
    month,
    year,
    session_type,
    SUM(session_pageviews) AS total_pageviews_per_visitor
  FROM
    session_classification
  WHERE
    session_type IN ('Purchase', 'Non-Purchase')
  GROUP BY
    fullVisitorId,
    month,
    year,
    session_type
)
GROUP BY
  year,
  month,
  session_type
ORDER BY
  year,
  month,
  session_type;