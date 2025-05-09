/*  Percentage of new users (first session between 2016‑08‑01 and 2017‑04‑30)
    who (1) spent more than 5 minutes on that first session and
    (2) completed a purchase in any later session                                   */

WITH sessions AS (      -- all sessions we will need
  SELECT
    fullVisitorId,
    visitStartTime,
    PARSE_DATE('%Y%m%d', date)                            AS session_date,
    IFNULL(totals.timeOnSite,0)                           AS time_on_site,
    IFNULL(totals.newVisits,0)                            AS is_new_visit,
    IFNULL(totals.transactions,0)                         AS transactions,
    IFNULL(totals.transactionRevenue,0)                   AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'   -- covers the whole period we may need
),

first_sessions AS (      -- timestamp of the very first session for every user
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_ts
  FROM sessions
  GROUP BY fullVisitorId
),

new_users AS (           -- users whose VERY FIRST session is inside the target window
  SELECT
    fs.fullVisitorId,
    fs.first_visit_ts,
    s.time_on_site
  FROM first_sessions  fs
  JOIN sessions        s
    ON  s.fullVisitorId = fs.fullVisitorId
    AND s.visitStartTime = fs.first_visit_ts            -- pick the first session row itself
  WHERE s.session_date BETWEEN DATE '2016-08-01' AND DATE '2017-04-30'
    AND s.is_new_visit = 1                              -- GA flag telling it is a new visitor
),

qualified_new_users AS ( -- they stayed > 5 minutes on that first session
  SELECT
    fullVisitorId,
    first_visit_ts
  FROM new_users
  WHERE time_on_site > 300
),

purchasing_users AS (    -- those qualified users that purchased later
  SELECT DISTINCT
    q.fullVisitorId
  FROM qualified_new_users q
  JOIN sessions s
      ON s.fullVisitorId = q.fullVisitorId
     AND s.visitStartTime > q.first_visit_ts           -- must be a later session
  WHERE s.transactions > 0 OR s.revenue > 0
)

SELECT
  ROUND(
        SAFE_DIVIDE(
          (SELECT COUNT(DISTINCT fullVisitorId) FROM purchasing_users),
          (SELECT COUNT(DISTINCT fullVisitorId) FROM new_users)
        ) * 100,
        4
  ) AS pct_new_users_meeting_criteria
;