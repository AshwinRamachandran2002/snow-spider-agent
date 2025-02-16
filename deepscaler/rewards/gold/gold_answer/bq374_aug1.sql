-- Task: Calculate the number of new users between August 1, 2016, and April 30, 2017, who on their initial visit stayed on the site for more than 5 minutes.
SELECT COUNT(DISTINCT s1.fullVisitorId) AS Number_of_new_users_stayed_over_5_minutes
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s1
WHERE s1._TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
  AND s1.totals.newVisits = 1
  AND s1.visitNumber = 1
  AND IFNULL(s1.totals.timeOnSite, 0) > 300