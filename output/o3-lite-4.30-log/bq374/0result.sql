WITH new_users AS (
  SELECT DISTINCT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
    AND totals.newVisits = 1
),
qualified_first AS (
  SELECT DISTINCT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
    AND totals.newVisits = 1
    AND visitNumber = 1
    AND totals.timeOnSite > 300           -- stayed more than 5 minutes
),
purchasers AS (
  SELECT DISTINCT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE (totals.transactions > 0 OR totals.totalTransactionRevenue > 0)
    AND visitNumber > 1                   -- purchase on a later visit
),
both_conditions AS (
  SELECT q.fullVisitorId
  FROM qualified_first q
  JOIN purchasers p USING (fullVisitorId)
)
SELECT
  ROUND(
    100 * COUNT(DISTINCT fullVisitorId)
/   (SELECT COUNT(*) FROM new_users)
  , 4
  ) AS percentage_new_users_with_5min_session_and_purchase
FROM both_conditions;