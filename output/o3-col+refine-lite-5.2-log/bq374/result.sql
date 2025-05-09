/*  Percentage of new users (Aug‑01‑2016 – Apr‑30‑2017) who
    1) stayed > 5 min on their very first visit, and
    2) completed ≥ 1 transaction on any later visit          */

WITH all_sessions AS (
  SELECT
    fullVisitorId,
    visitNumber,
    totals.timeOnSite      AS timeOnSite,
    totals.transactions    AS transactions,
    totals.newVisits       AS newVisits
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'          -- date range
),

-- 1. users whose very first (new) visit lasted > 5 minutes
first_long AS (
  SELECT DISTINCT fullVisitorId
  FROM all_sessions
  WHERE newVisits = 1
    AND visitNumber = 1
    AND timeOnSite > 300                                         -- > 5 minutes
),

-- 2. users who purchased on a later visit
later_purchase AS (
  SELECT DISTINCT fullVisitorId
  FROM all_sessions
  WHERE transactions IS NOT NULL
    AND transactions > 0
    AND visitNumber > 1                                          -- later than first
),

-- intersection of the two groups
both_conditions AS (
  SELECT fullVisitorId
  FROM first_long
  INTERSECT DISTINCT
  SELECT fullVisitorId
  FROM later_purchase
)

SELECT
  (SELECT COUNT(*) FROM both_conditions) AS users_long_first_and_buy_later,
  (SELECT COUNT(DISTINCT fullVisitorId)
     FROM all_sessions
     WHERE newVisits = 1)          AS total_new_users,
  ROUND(
    SAFE_DIVIDE(
      (SELECT COUNT(*) FROM both_conditions),
      (SELECT COUNT(DISTINCT fullVisitorId)
         FROM all_sessions
         WHERE newVisits = 1)
    ) * 100, 4)                    AS percent_of_new_users
;