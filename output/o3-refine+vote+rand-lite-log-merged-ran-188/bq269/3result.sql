-- Average pageviews per visitor for purchase vs. non‑purchase sessions
-- (June & July 2017)

WITH sessions AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', `date`)) AS month,
    fullVisitorId                                          AS visitor_id,
    IF(totals.transactions >= 1, 'purchase', 'non_purchase') AS session_type,
    totals.pageviews                                       AS pageviews
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE
        `date` BETWEEN '20170601' AND '20170731'          -- time window
    AND totals.pageviews IS NOT NULL                      -- keep sessions with pageviews
),

per_visitor AS (
  -- total pageviews each visitor generated in the month / session type
  SELECT
    month,
    visitor_id,
    session_type,
    SUM(pageviews) AS total_pageviews
  FROM sessions
  GROUP BY month, visitor_id, session_type
),

avg_per_month AS (
  -- average pageviews per visitor for each session type within the month
  SELECT
    month,
    session_type,
    AVG(total_pageviews) AS avg_pageviews
  FROM per_visitor
  GROUP BY month, session_type
)

SELECT
  month,
  ROUND(MAX(IF(session_type = 'purchase'     , avg_pageviews, NULL)), 4) AS purchase_avg_pageviews,
  ROUND(MAX(IF(session_type = 'non_purchase' , avg_pageviews, NULL)), 4) AS non_purchase_avg_pageviews
FROM avg_per_month
GROUP BY month
ORDER BY month;