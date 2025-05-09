WITH -- 1) first (new‑user) session that happened between 1‑Aug‑2016 and 30‑Apr‑2017
initial_session AS (
  SELECT
    fullVisitorId,
    visitStartTime          AS init_visit_ts,
    totals.timeOnSite       AS init_time_on_site
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'   -- date range of interest
        AND totals.newVisits = 1                          -- “new user” flag
  QUALIFY visitStartTime = MIN(visitStartTime) OVER (PARTITION BY fullVisitorId)
), 

-- 2) keep only those new users whose very first session lasted > 5 minutes
qualified_new_users AS (
  SELECT *
  FROM   initial_session
  WHERE  init_time_on_site > 300                     -- > 5 minutes
),

-- 3) find those qualified users who bought on ANY later visit (after their first one)
buyers_after_first_visit AS (
  SELECT DISTINCT s.fullVisitorId
  FROM   `bigquery-public-data.google_analytics_sample.ga_sessions_*` s
  JOIN   qualified_new_users q
         ON  s.fullVisitorId = q.fullVisitorId
         AND s.visitStartTime > q.init_visit_ts      -- must be a later session
  WHERE  s.totals.transactions >= 1                  -- purchase occurred
)

-- 4) percentage of qualified new users who later purchased
SELECT
  ROUND(
        SAFE_DIVIDE( COUNT(DISTINCT b.fullVisitorId),
                     COUNT(DISTINCT q.fullVisitorId) ) * 100
       , 4) AS pct_new_users_who_bought_after_5min_first_visit
FROM   qualified_new_users q
LEFT JOIN buyers_after_first_visit b
       ON q.fullVisitorId = b.fullVisitorId;