SELECT
  ROUND(
    SAFE_DIVIDE(q.qualified_users , n.total_new_users) * 100
  , 4) AS percentage_new_users_with_5min_session_and_purchase
FROM
  ( /* users whose first session (>5 min) is in the period
       and who purchase in a later session also within the period */
    SELECT COUNT(DISTINCT first.fullVisitorId) AS qualified_users
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS first
    WHERE first._TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
      AND first.totals.newVisits = 1          -- new user
      AND first.visitNumber       = 1         -- first session
      AND first.totals.timeOnSite > 300       -- >5 minutes
      AND EXISTS (
          SELECT 1
          FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS later
          WHERE later._TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
            AND later.fullVisitorId  = first.fullVisitorId
            AND later.visitStartTime > first.visitStartTime   -- later session
            AND IFNULL(later.totals.transactions, 0) > 0      -- made purchase
      )
  ) AS q
CROSS JOIN
  ( /* total number of new users in the period */
    SELECT COUNT(DISTINCT fullVisitorId) AS total_new_users
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
      AND totals.newVisits = 1
  ) AS n;