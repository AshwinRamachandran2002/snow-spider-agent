/*  Average page-views per visitor for purchase vs. non-purchase sessions
    (June – July 2017), shown side-by-side for each month. */

WITH sessions AS (
  -- 1.  Keep only June-July 2017 sessions that have at least one page-view
  SELECT
    CONCAT(SUBSTR(`date`,1,4),'-',SUBSTR(`date`,5,2))                AS month,
    `fullVisitorId`,
    `totals`.`pageviews`                                             AS pageviews,
    CASE
      WHEN `totals`.`transactions` IS NOT NULL
           AND `totals`.`transactions` > 0 THEN 'purchase'
      ELSE 'non_purchase'
    END                                                             AS session_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
    AND `totals`.`pageviews` IS NOT NULL
),

per_visitor AS (
  -- 2.  Sum all page-views each visitor generated in a month / class
  SELECT
    month,
    `fullVisitorId`,
    session_type,
    SUM(pageviews) AS pv_per_visitor
  FROM sessions
  GROUP BY month, `fullVisitorId`, session_type
),

avg_pv AS (
  -- 3.  Average those page-view totals across visitors
  SELECT
    month,
    session_type,
    AVG(pv_per_visitor) AS avg_pageviews_per_visitor
  FROM per_visitor
  GROUP BY month, session_type
)

-- 4.  Pivot to show purchase & non-purchase side-by-side
SELECT
  month,
  MAX(IF(session_type = 'purchase',     avg_pageviews_per_visitor, NULL)) AS purchase_avg_pageviews,
  MAX(IF(session_type = 'non_purchase', avg_pageviews_per_visitor, NULL)) AS non_purchase_avg_pageviews
FROM avg_pv
GROUP BY month
ORDER BY month;