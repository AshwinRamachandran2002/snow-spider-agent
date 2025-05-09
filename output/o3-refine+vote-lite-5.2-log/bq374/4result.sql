/*  Percentage of new users (first session between 2016‑08‑01 and 2017‑04‑30)
    who stayed on site >5 minutes during that first visit
    AND completed a purchase in any later session                                     */

WITH all_sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    totals.timeOnSite        AS time_on_site,
    totals.newVisits         AS is_new_visit,
    totals.transactions      AS transactions,
    _TABLE_SUFFIX            AS session_date           --  YYYYMMDD
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- first (initial) session for users whose very first visit
-- falls between 2016‑08‑01 and 2017‑04‑30
initial_visits AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_ts
  FROM all_sessions
  WHERE session_date BETWEEN '20160801' AND '20170430'
        AND is_new_visit = 1
  GROUP BY fullVisitorId
),

initial_visit_details AS (
  SELECT
    s.fullVisitorId,
    s.time_on_site,
    s.visitStartTime
  FROM all_sessions  AS s
  JOIN initial_visits AS i
    ON s.fullVisitorId   = i.fullVisitorId
   AND s.visitStartTime  = i.first_visit_ts          -- keeps exactly the initial session
),

-- users who made at least one purchase AFTER their initial visit
subsequent_purchasers AS (
  SELECT DISTINCT s.fullVisitorId
  FROM all_sessions         AS s
  JOIN initial_visit_details AS i
    ON s.fullVisitorId = i.fullVisitorId
  WHERE s.visitStartTime > i.visitStartTime          -- later session
        AND s.transactions  >= 1                     -- at least one transaction
)

SELECT
  COUNT(*)                                                   AS total_new_users,
  COUNTIF(time_on_site > 300)                                AS new_users_5min_plus,
  COUNTIF(time_on_site > 300
          AND fullVisitorId IN (SELECT fullVisitorId
                                FROM subsequent_purchasers)) AS qualified_users,
  ROUND(
        SAFE_DIVIDE(
          COUNTIF(time_on_site > 300
                  AND fullVisitorId IN (SELECT fullVisitorId
                                        FROM subsequent_purchasers)),
          COUNT(*)
        ) * 100
       , 4)                                                  AS percentage_qualified_users
FROM initial_visit_details;