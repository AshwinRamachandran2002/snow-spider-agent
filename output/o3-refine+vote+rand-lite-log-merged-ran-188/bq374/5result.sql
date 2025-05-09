/* Percentage of new users (first session between 2016-08-01 and 2017-04-30)
   who stayed > 5 minutes on that first visit AND purchased in any later visit */
WITH first_sessions AS (
  -- first (new) visit for every user in the period
  SELECT
    fullVisitorId,
    ARRAY_AGG(visitNumber ORDER BY visitStartTime ASC  LIMIT 1)[OFFSET(0)]
        AS first_visit_number,
    ARRAY_AGG(totals.timeOnSite ORDER BY visitStartTime ASC LIMIT 1)[OFFSET(0)]
        AS first_time_on_site
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
    AND totals.newVisits = 1
  GROUP BY fullVisitorId
),
eligible_users AS (       -- first-visit time-on-site > 5 minutes
  SELECT fullVisitorId, first_visit_number
  FROM first_sessions
  WHERE first_time_on_site > 300
),
purchasers AS (           -- those eligible users who later generated revenue
  SELECT DISTINCT s.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
  JOIN eligible_users               AS e
    ON s.fullVisitorId = e.fullVisitorId
  WHERE s.visitNumber > e.first_visit_number          -- after the first visit
    AND s.totals.transactionRevenue IS NOT NULL
    AND s.totals.transactionRevenue > 0
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      (SELECT COUNT(*) FROM purchasers),     -- numerator
      (SELECT COUNT(*) FROM first_sessions)  -- denominator (all new users)
    ) * 100,
    4
  ) AS pct_new_users_timegt5min_with_later_purchase
;