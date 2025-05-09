-- Percentage of new users (Aug-01-2016 – Apr-30-2017) whose
-- very first session lasted >5 min and who later completed a purchase
WITH period_sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    totals.newVisits            AS is_new_session,
    totals.timeOnSite,
    totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
),

-- All new users in the period (denominator)
new_users AS (
  SELECT DISTINCT fullVisitorId
  FROM period_sessions
  WHERE is_new_session = 1
),

-- Their first sessions that lasted >5 min
initial_long AS (
  SELECT
    fullVisitorId,
    visitStartTime AS init_time
  FROM period_sessions
  WHERE is_new_session = 1
    AND timeOnSite > 300
),

-- Any purchase sessions in the period
later_purchases AS (
  SELECT
    fullVisitorId,
    visitStartTime AS purchase_time
  FROM period_sessions
  WHERE transactions >= 1
),

-- Users who meet both conditions: long first visit AND later purchase
qualified AS (
  SELECT DISTINCT il.fullVisitorId
  FROM initial_long il
  JOIN later_purchases lp
    ON lp.fullVisitorId = il.fullVisitorId
   AND lp.purchase_time > il.init_time
),

-- Final counts & percentage
counts AS (
  SELECT
    (SELECT COUNT(*) FROM qualified)      AS qualified_users,
    (SELECT COUNT(*) FROM new_users)      AS total_new_users
)

SELECT
  qualified_users,
  total_new_users,
  ROUND(SAFE_DIVIDE(qualified_users, total_new_users) * 100, 4) AS percent_of_new_users
FROM counts;