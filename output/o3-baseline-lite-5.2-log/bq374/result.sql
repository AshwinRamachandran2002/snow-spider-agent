/* Percentage of new users (first session between 2016‑08‑01 and 2017‑04‑30)
   who 1) spent more than 5 minutes ( >300 sec ) in that first session and
   2) completed a transaction in any later session. */

WITH initial_sessions AS (         -- one row = the first session of a new user
  SELECT
    fullVisitorId,
    INIT.visitStartTime   AS init_visitStartTime,
    INIT.timeOnSite       AS init_timeOnSite
  FROM (
    SELECT
      fullVisitorId,
      ARRAY_AGG(
        STRUCT( visitStartTime,
                IFNULL(totals.timeOnSite,0) AS timeOnSite )
        ORDER BY visitStartTime ASC           -- earliest session first
        LIMIT 1
      )[OFFSET(0)]                            -- keep only the earliest
      AS INIT
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'     -- period of interest
      AND totals.newVisits = 1                                -- first visit
    GROUP BY fullVisitorId
  )
),

long_stay_users AS (               -- first‑session time‑on‑site > 5 minutes
  SELECT fullVisitorId
  FROM   initial_sessions
  WHERE  init_timeOnSite > 300
),

purchase_users AS (                -- user bought in any later visit
  SELECT DISTINCT i.fullVisitorId
  FROM   initial_sessions  AS i
  JOIN   `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
         ON  s.fullVisitorId   = i.fullVisitorId
  WHERE  _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'      -- include later sessions
    AND  s.visitStartTime  > i.init_visitStartTime            -- must be a later visit
    AND (IFNULL(s.totals.transactions,0)      >= 1            -- purchase made
         OR IFNULL(s.totals.transactionRevenue,0) > 0)
),

both_conditions AS (               -- users satisfying both requirements
  SELECT ls.fullVisitorId
  FROM   long_stay_users ls
  JOIN   purchase_users  pu USING (fullVisitorId)
)

SELECT
  ROUND( SAFE_DIVIDE(
           (SELECT COUNT(DISTINCT fullVisitorId) FROM both_conditions),
           (SELECT COUNT(DISTINCT fullVisitorId) FROM initial_sessions)
         ) * 100 , 4)  AS percentage_of_new_users
;