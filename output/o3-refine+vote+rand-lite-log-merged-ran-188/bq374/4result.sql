/*  Percentage of new users (Aug-01-2016 → Apr-30-2017) whose
    very first session lasted > 5 minutes AND who completed
    ≥1 transaction in any later session                        */
WITH all_sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    totals.newVisits                      AS is_new_user,
    IFNULL(totals.timeOnSite,0)           AS time_on_site_sec,
    IFNULL(totals.transactions,0)         AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
),

-- 1️⃣  first session timestamp of every *new* visitor
first_visits AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_ts
  FROM all_sessions
  WHERE is_new_user = 1
  GROUP BY fullVisitorId
),

-- 2️⃣  keep only those first sessions that lasted > 300 sec
qualified_first_sessions AS (
  SELECT
    f.fullVisitorId,
    f.first_ts
  FROM first_visits            AS f
  JOIN all_sessions            AS s
    ON  s.fullVisitorId  = f.fullVisitorId
   AND s.visitStartTime = f.first_ts
  WHERE s.time_on_site_sec > 300
),

-- 3️⃣  users who made ≥1 purchase in any *later* session
later_purchases AS (
  SELECT DISTINCT s.fullVisitorId
  FROM all_sessions              AS s
  JOIN qualified_first_sessions  AS q
    ON  s.fullVisitorId = q.fullVisitorId
   AND s.visitStartTime > q.first_ts       -- later visit
  WHERE s.transactions > 0
)

SELECT
  COUNT(*)                                           AS qualified_and_purchased,
  (SELECT COUNT(DISTINCT fullVisitorId)
     FROM all_sessions
     WHERE is_new_user = 1)                          AS total_new_users,
  SAFE_DIVIDE(COUNT(*),
              (SELECT COUNT(DISTINCT fullVisitorId)
                 FROM all_sessions
                 WHERE is_new_user = 1)) * 100
    AS pct_new_users_stayed_5min_purchased
FROM later_purchases;