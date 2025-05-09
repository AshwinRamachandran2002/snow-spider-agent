/*  Percentage of new users (Aug‑01‑2016 – Apr‑30‑2017) whose first
    session lasted more than 5 minutes AND who completed at least one
    transaction in any later session (same user, later time).            */

WITH sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    IFNULL(totals.timeOnSite,0)            AS time_on_site,      -- seconds
    totals.newVisits                       AS is_new_visit,
    IFNULL(totals.transactions,0)          AS transactions
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'              -- Aug‑01‑2016 … Apr‑30‑2017
),

/* First (initial) session for every new user within the period */
initial_sessions AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime)            AS first_session_time,
    ANY_VALUE(time_on_site)        AS first_session_time_on_site
  FROM
    sessions
  WHERE
    is_new_visit = 1                                          -- guarantees it is the user’s very first visit
  GROUP BY
    fullVisitorId
),

/* Users who purchased in ANY later session */
purchasers_later AS (
  SELECT DISTINCT
    s.fullVisitorId
  FROM
    sessions            AS s
  JOIN
    initial_sessions    AS i
  USING (fullVisitorId)
  WHERE
        s.visitStartTime > i.first_session_time               -- later than the first session
    AND s.transactions  > 0                                   -- at least one transaction
),

/* Initial‑session condition: stayed > 5 minutes (300 seconds) */
qualified_users AS (
  SELECT
    i.fullVisitorId
  FROM
    initial_sessions i
  JOIN
    purchasers_later  p
  USING (fullVisitorId)
  WHERE
    i.first_session_time_on_site > 300                        -- > 5 minutes
)

/* ------------------------------------------------------------- */
/*           Compute the requested percentage                     */
SELECT
  SAFE_DIVIDE( COUNT(DISTINCT q.fullVisitorId),
               COUNT(DISTINCT i.fullVisitorId) ) * 100
    AS percentage_of_new_users
FROM
  initial_sessions i
LEFT JOIN
  qualified_users q
ON
  i.fullVisitorId = q.fullVisitorId;