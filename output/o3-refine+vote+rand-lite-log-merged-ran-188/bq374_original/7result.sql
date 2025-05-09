/*  Percentage of new users (first‑ever session between 1‑Aug‑2016
    and 30‑Apr‑2017) whose initial visit lasted >5 minutes and who
    completed at least one transaction in any later session       */

WITH all_sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,                              -- seconds since epoch
    SAFE_CAST(PARSE_DATE('%Y%m%d', date) AS DATE) AS session_date,
    SAFE_CAST(totals.timeOnSite AS INT64)        AS time_on_site,      -- seconds
    SAFE_CAST(totals.transactions AS INT64)      AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  -- keep every table we have (the wildcard already limits us to 2016‑2017 data)
),

-- first session ever seen for each user
first_sessions AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_ts
  FROM all_sessions
  GROUP BY fullVisitorId
),

-- users whose very first session falls in the requested period
new_users AS (
  SELECT
    fs.fullVisitorId,
    fs.first_visit_ts,
    s.time_on_site
  FROM first_sessions fs
  JOIN all_sessions s
    ON s.fullVisitorId = fs.fullVisitorId
   AND s.visitStartTime = fs.first_visit_ts          -- the initial session row
  WHERE DATE(TIMESTAMP_SECONDS(fs.first_visit_ts)) 
        BETWEEN DATE '2016-08-01' AND DATE '2017-04-30'
),

-- of those new users, keep only the ones who stayed > 5 minutes (300 s)
initial_long_visit AS (
  SELECT
    fullVisitorId,
    first_visit_ts
  FROM new_users
  WHERE time_on_site > 300
),

-- among the above, check whether any later session contains a purchase
qualified_users AS (
  SELECT DISTINCT
    ilv.fullVisitorId
  FROM initial_long_visit ilv
  JOIN all_sessions s
    ON s.fullVisitorId = ilv.fullVisitorId
   AND s.visitStartTime > ilv.first_visit_ts        -- later than the initial visit
  WHERE s.transactions > 0                          -- at least one transaction
)

SELECT
  ROUND(
        SAFE_DIVIDE(
          (SELECT COUNT(*) FROM qualified_users) ,        -- numerator
          (SELECT COUNT(*) FROM new_users)                -- denominator
        ) * 100
       , 4)                                            AS percentage_of_new_users
;