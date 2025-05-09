WITH sessions AS (
  SELECT
    date,
    fullVisitorId,
    totals.pageviews AS totals_pageviews,
    PARSE_DATE('%Y%m%d', date) AS session_date,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM UNNEST(hits) AS hit
        WHERE hit.eCommerceAction.action_type = "6"
      ) THEN 'purchase'
      ELSE 'non_purchase'
    END AS classification
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`
  WHERE totals.pageviews IS NOT NULL

  UNION ALL

  SELECT
    date,
    fullVisitorId,
    totals.pageviews AS totals_pageviews,
    PARSE_DATE('%Y%m%d', date) AS session_date,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM UNNEST(hits) AS hit
        WHERE hit.eCommerceAction.action_type = "6"
      ) THEN 'purchase'
      ELSE 'non_purchase'
    END AS classification
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
  WHERE totals.pageviews IS NOT NULL
),
classified_sessions AS (
  SELECT
    EXTRACT(MONTH FROM session_date) AS month_number,
    CASE EXTRACT(MONTH FROM session_date)
      WHEN 6 THEN 'June 2017'
      WHEN 7 THEN 'July 2017'
    END AS Month,
    fullVisitorId,
    totals_pageviews,
    classification
  FROM sessions
),
visitor_pageviews AS (
  SELECT
    Month,
    month_number,
    fullVisitorId,
    classification,
    SUM(totals_pageviews) AS total_pageviews
  FROM classified_sessions
  GROUP BY Month, month_number, fullVisitorId, classification
),
average_pageviews AS (
  SELECT
    Month,
    month_number,
    classification,
    AVG(total_pageviews) AS avg_pageviews_per_visitor
  FROM visitor_pageviews
  GROUP BY Month, month_number, classification
)
SELECT
  Month,
  ROUND(MAX(CASE WHEN classification = 'purchase' THEN avg_pageviews_per_visitor END), 4) AS Purchase_Average_Pageviews,
  ROUND(MAX(CASE WHEN classification = 'non_purchase' THEN avg_pageviews_per_visitor END), 4) AS Non_Purchase_Average_Pageviews
FROM average_pageviews
GROUP BY Month, month_number
ORDER BY month_number