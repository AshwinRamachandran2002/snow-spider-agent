SELECT
  ROUND((
    SELECT COUNT(DISTINCT s1.fullVisitorId)
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s1
    WHERE s1._TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
      AND s1.totals.newVisits = 1
      AND s1.visitNumber = 1
      AND IFNULL(s1.totals.timeOnSite, 0) > 300
      AND EXISTS (
        SELECT 1
        FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s2
        WHERE s2.fullVisitorId = s1.fullVisitorId
          AND s2.visitNumber > 1
          AND IFNULL(s2.totals.transactions, 0) > 0
      )
  ) * 100.0 /
  (
    SELECT COUNT(DISTINCT s3.fullVisitorId)
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s3
    WHERE s3._TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
      AND s3.totals.newVisits = 1
  ), 4) AS Percentage_of_new_users_who_stayed_over_5_minutes_and_made_purchase