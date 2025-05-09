-- % of new users (Aug-01-2016 → Apr-30-2017) whose first visit
-- lasted > 5 min and who later completed a purchase
WITH first_sessions AS (      -- each user’s very first visit in the period
  SELECT
    fullVisitorId,
    visitStartTime                      AS first_ts,
    totals.timeOnSite                   AS time_on_site
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
    AND totals.newVisits = 1            -- marks new users
  QUALIFY ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                             ORDER BY visitStartTime) = 1
),
long_first_sessions AS (      -- first visits longer than 5 minutes
  SELECT
    fullVisitorId,
    first_ts
  FROM first_sessions
  WHERE time_on_site > 300               -- seconds
),
later_buyers AS (            -- those users who bought in any later session
  SELECT DISTINCT s.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
  JOIN long_first_sessions AS l
    ON s.fullVisitorId = l.fullVisitorId
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
    AND s.visitStartTime > l.first_ts    -- after initial visit
    AND s.totals.transactions > 0
)
SELECT
  100 * COUNT(DISTINCT later_buyers.fullVisitorId) /
        (SELECT COUNT(*) FROM first_sessions) AS pct_new_users_longstay_buy
FROM later_buyers;