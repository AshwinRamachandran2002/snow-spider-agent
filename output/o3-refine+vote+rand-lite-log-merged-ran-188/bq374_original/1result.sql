/*  Percentage of new users (first‑time visits between 2016‑08‑01 and 2017‑04‑30)
    who spent more than five minutes on that first visit AND
    completed a purchase (totals.transactions > 0) on any later visit          */

WITH sessions AS (
  SELECT
      fullVisitorId,
      visitStartTime,
      totals.newVisits                        AS is_new_visit,
      COALESCE(totals.timeOnSite ,0)  AS time_on_site,
      COALESCE(totals.transactions ,0) AS transactions,
      _TABLE_SUFFIX                           AS session_date               --  YYYYMMDD
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  -- read only the part of the demo dataset that is available
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
),

/* first (new‑user) sessions that fall inside the requested window */
initial_sessions AS (
  SELECT
      fullVisitorId,
      visitStartTime                 AS first_visit_ts,
      time_on_site
  FROM sessions
  WHERE session_date BETWEEN '20160801' AND '20170430'
    AND is_new_visit = 1
),

/* earliest purchase time (if any) for every visitor */
first_purchase AS (
  SELECT
      fullVisitorId,
      MIN(visitStartTime) AS purchase_ts
  FROM sessions
  WHERE transactions > 0
  GROUP BY fullVisitorId
),

/* visitors who met both conditions:
   (a) > 5 minutes on first visit, (b) later purchase */
qualified_users AS (
  SELECT
      i.fullVisitorId
  FROM initial_sessions i
  JOIN first_purchase   p
    ON i.fullVisitorId = p.fullVisitorId
   AND p.purchase_ts   > i.first_visit_ts          -- purchase occurred later
  WHERE i.time_on_site > 300                       -- more than 5 minutes
)

SELECT
  ROUND(
        SAFE_DIVIDE(COUNT(DISTINCT q.fullVisitorId),
                    COUNT(DISTINCT i.fullVisitorId)) * 100, 4
       ) AS percent_new_users
FROM initial_sessions  i
LEFT JOIN qualified_users q
       ON i.fullVisitorId = q.fullVisitorId;