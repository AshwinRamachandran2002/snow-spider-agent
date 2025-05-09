-- Percentage of new users (Aug-01-2016 → Apr-30-2017) whose
--  • first visit lasted >5 minutes, and
--  • made a purchase in any later session.
WITH first_long_visit AS (          -- first visit (>5 min) in the period
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_ts
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
    AND totals.newVisits = 1
    AND totals.timeOnSite  > 300          -- >5 minutes
  GROUP BY fullVisitorId
),
purchasers AS (                     -- users with a later purchase
  SELECT DISTINCT s.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
  JOIN first_long_visit AS f
    ON s.fullVisitorId = f.fullVisitorId
  WHERE s.visitStartTime > f.first_visit_ts
    AND s.totals.transactions IS NOT NULL
    AND s.totals.transactions > 0
),
total_new AS (                      -- all new users in the period
  SELECT COUNT(DISTINCT fullVisitorId) AS total_new_users
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
    AND totals.newVisits = 1
)
SELECT
  (SELECT COUNT(*) FROM purchasers)                    AS users_with_both_conditions,
  (SELECT total_new_users FROM total_new)              AS total_new_users,
  SAFE_DIVIDE(
    (SELECT COUNT(*) FROM purchasers),
    (SELECT total_new_users FROM total_new)
  ) * 100                                              AS percentage_users_meeting_conditions