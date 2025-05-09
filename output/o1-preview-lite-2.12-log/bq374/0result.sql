WITH
  total_new_users AS (
    SELECT COUNT(DISTINCT fullVisitorId) AS total
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE totals.newVisits = 1
      AND _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
  ),
  new_users_over_5min AS (
    SELECT DISTINCT fullVisitorId
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE totals.newVisits = 1
      AND visitNumber = 1
      AND totals.timeOnSite > 300
      AND _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
  ),
  users_met_all_criteria AS (
    SELECT COUNT(DISTINCT fullVisitorId) AS num_users_met_criteria
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE fullVisitorId IN (
      SELECT fullVisitorId FROM new_users_over_5min
    )
    AND visitNumber > 1
    AND totals.transactions >= 1
  )
SELECT ROUND(
  (users_met_all_criteria.num_users_met_criteria / total_new_users.total) * 100, 4
) AS Percentage_of_new_users_who_stayed_over_5_minutes_and_made_purchase
FROM users_met_all_criteria, total_new_users;