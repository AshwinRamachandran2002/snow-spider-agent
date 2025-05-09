/*  Percentage of brand-new users (Aug-01-2016 .. Apr-30-2017) whose
    very first session lasted >5 minutes AND who completed a purchase
    in any later session within the same analysis window              */

WITH sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    totals.newVisits           AS newVisits,
    totals.timeOnSite          AS timeOnSite,
    totals.transactions        AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
),

-- first session timestamp for every visitor in the window
first_session AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_ts
  FROM sessions
  GROUP BY fullVisitorId
),

-- metrics of each visitor’s first session
first_session_metrics AS (
  SELECT
    s.fullVisitorId,
    s.timeOnSite,
    s.newVisits
  FROM sessions   AS s
  JOIN first_session AS f
    ON s.fullVisitorId = f.fullVisitorId
   AND s.visitStartTime = f.first_ts
),

-- visitors whose first visit was a NEW visit and lasted >5 minutes
good_first_visit AS (
  SELECT fullVisitorId
  FROM first_session_metrics
  WHERE newVisits = 1        -- flagged as brand-new
    AND timeOnSite > 300     -- >5 minutes (300 seconds)
),

-- visitors who made at least one transaction in any later session
later_purchasers AS (
  SELECT DISTINCT s.fullVisitorId
  FROM sessions AS s
  JOIN first_session f
    ON s.fullVisitorId = f.fullVisitorId
  WHERE s.visitStartTime > f.first_ts   -- after the first visit
    AND s.transactions > 0              -- purchase occurred
),

-- users that satisfy BOTH conditions
qualified_users AS (
  SELECT DISTINCT gf.fullVisitorId
  FROM good_first_visit gf
  JOIN later_purchasers lp
    USING (fullVisitorId)
),

-- denominator: all brand-new users during the window
all_new_users AS (
  SELECT DISTINCT fullVisitorId
  FROM sessions
  WHERE newVisits = 1
)

SELECT
  ROUND(100 * COUNT(DISTINCT qu.fullVisitorId)
            / COUNT(DISTINCT an.fullVisitorId), 4) AS pct_new_users_meeting_conditions
FROM all_new_users an
LEFT JOIN qualified_users qu
  ON an.fullVisitorId = qu.fullVisitorId;