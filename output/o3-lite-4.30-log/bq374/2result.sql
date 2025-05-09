WITH sessions AS (
  SELECT
    fullVisitorId,
    visitNumber,
    visitStartTime,
    totals.newVisits     AS new_visit,
    totals.timeOnSite    AS time_on_site,
    totals.transactions  AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'          -- 01‑Aug‑2016 … 30‑Apr‑2017
),
first_visits AS (                                                  -- first session of every new user
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_ts
  FROM sessions
  WHERE new_visit = 1
  GROUP BY fullVisitorId
),
long_first AS (                                                    -- first sessions that lasted >5 min
  SELECT DISTINCT s.fullVisitorId
  FROM first_visits fv
  JOIN sessions    s
    ON s.fullVisitorId = fv.fullVisitorId
   AND s.visitStartTime = fv.first_ts
  WHERE s.time_on_site > 300
),
purchasers AS (                                                    -- users who bought in a later session
  SELECT DISTINCT s.fullVisitorId
  FROM sessions     s
  JOIN first_visits fv
    ON s.fullVisitorId = fv.fullVisitorId
  WHERE s.visitStartTime > fv.first_ts
    AND s.transactions IS NOT NULL
    AND s.transactions > 0
),
qualified AS (                                                     -- users satisfying both conditions
  SELECT fullVisitorId FROM long_first
  INTERSECT DISTINCT
  SELECT fullVisitorId FROM purchasers
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      (SELECT COUNT(*) FROM qualified),                           -- numerator
      (SELECT COUNT(DISTINCT fullVisitorId) FROM first_visits)    -- denominator
    ),
    4
  ) AS percentage_new_users_with_5min_session_and_purchase;