-- Percentage of new users (Aug-01-2016 – Apr-30-2017) whose
-- first visit lasted >5 min and who purchased in any later visit
WITH all_sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    totals.newVisits            AS newVisits,
    totals.timeOnSite           AS timeOnSite,
    totals.transactions         AS transactions,
    totals.transactionRevenue   AS transactionRevenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
),

-- earliest session we see for each visitor in the period
first_sessions AS (
  SELECT
    fullVisitorId,
    ARRAY_AGG(
      STRUCT(visitStartTime, timeOnSite, newVisits)
      ORDER BY visitStartTime ASC
      LIMIT 1
    )[OFFSET(0)] AS first
  FROM all_sessions
  GROUP BY fullVisitorId
),

-- visitors whose first session qualifies and who later purchased
qualifying_users AS (
  SELECT DISTINCT fs.fullVisitorId
  FROM first_sessions fs
  JOIN all_sessions s
    ON s.fullVisitorId = fs.fullVisitorId
  WHERE fs.first.newVisits = 1                 -- new user
    AND fs.first.timeOnSite > 300              -- >5 minutes on first visit
    AND s.visitStartTime > fs.first.visitStartTime
    AND (s.transactions IS NOT NULL
         OR s.transactionRevenue IS NOT NULL)  -- later purchase
),

-- all new users observed in the period
total_new_users AS (
  SELECT DISTINCT fullVisitorId
  FROM all_sessions
  WHERE newVisits = 1
)

SELECT
  ROUND(
    100.0 * COUNT(DISTINCT q.fullVisitorId) / COUNT(DISTINCT t.fullVisitorId),
    4
  ) AS pct_qualifying_new_users
FROM total_new_users t
LEFT JOIN qualifying_users q
ON t.fullVisitorId = q.fullVisitorId;