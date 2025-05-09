-- Percentage of new users whose first visit lasted >5 minutes 
-- and who made a purchase in a later session (Aug-01-2016 – Apr-30-2017)

WITH first_session AS (
  -- grab every user’s very first NEW-visit session in the window
  SELECT
    fullVisitorId,
    ARRAY_AGG(
      STRUCT(date,
             totals.timeOnSite AS time_on_site,
             visitStartTime)
      ORDER BY visitStartTime
      LIMIT 1
    )[OFFSET(0)] AS fs
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
        AND totals.newVisits = 1
  GROUP BY fullVisitorId
),

qualified_first AS (
  -- keep only those first sessions that lasted > 5 minutes (300 s)
  SELECT
    fullVisitorId,
    fs.date AS first_date
  FROM first_session
  WHERE fs.time_on_site > 300
),

later_purchase AS (
  -- users who purchased in any later session within the same period
  SELECT DISTINCT s.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
  JOIN qualified_first q
    ON s.fullVisitorId = q.fullVisitorId
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
        AND s.date > q.first_date
        AND s.totals.transactions IS NOT NULL
)

SELECT
  ROUND(
    100 * COUNT(DISTINCT lp.fullVisitorId)
        / (SELECT COUNT(*) FROM first_session)
  , 2) AS pct_qualified
FROM later_purchase lp;