WITH sessions AS (
    ------------------------------------------------------------------
    -- Pull the fields we need from the GA session records
    ------------------------------------------------------------------
    SELECT
        "fullVisitorId"                                          AS user_id ,
        "visitStartTime"                                         AS visit_ts ,
        TO_DATE("date",'YYYYMMDD')                               AS session_date ,
        (PARSE_JSON("totals"):"newVisits")::NUMBER               AS is_new_visit ,
        (PARSE_JSON("totals"):"timeOnSite")::NUMBER              AS time_on_site ,
        COALESCE( (PARSE_JSON("totals"):"transactions")::NUMBER ,0)            AS transactions ,
        COALESCE( (PARSE_JSON("totals"):"totalTransactionRevenue")::NUMBER ,0) AS revenue
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160801"
),
----------------------------------------------------------------------
-- First-time ( “new visit” ) sessions that occurred between
-- 2016-08-01 and 2017-04-30
----------------------------------------------------------------------
first_sessions AS (
    SELECT
        user_id ,
        MIN(visit_ts) AS first_visit_ts
    FROM sessions
    WHERE is_new_visit = 1
      AND session_date BETWEEN '2016-08-01' AND '2017-04-30'
    GROUP BY user_id
),
----------------------------------------------------------------------
-- Keep only those first sessions whose on-site time exceeded 5 minutes
----------------------------------------------------------------------
qualified_first AS (
    SELECT f.user_id ,
           f.first_visit_ts
    FROM   first_sessions f
           JOIN sessions s
             ON s.user_id = f.user_id
            AND s.visit_ts = f.first_visit_ts
    WHERE  s.time_on_site > 300
),
----------------------------------------------------------------------
-- Users who made a purchase in any later session
----------------------------------------------------------------------
purchasing_users AS (
    SELECT  DISTINCT q.user_id
    FROM    qualified_first q
            JOIN sessions s
              ON s.user_id = q.user_id
             AND s.visit_ts > q.first_visit_ts
    WHERE   s.transactions > 0
        OR  s.revenue      > 0
),
----------------------------------------------------------------------
-- Summary counts
----------------------------------------------------------------------
totals AS (
    SELECT COUNT(*) AS total_new_users
    FROM   first_sessions
),
qualified AS (
    SELECT COUNT(*) AS purchasers_after_5min
    FROM   purchasing_users
)
----------------------------------------------------------------------
-- Final percentage
----------------------------------------------------------------------
SELECT
    ROUND( purchasers_after_5min * 100.0 / NULLIF(total_new_users,0) , 4)  AS pct_new_users_5min_then_purchase
FROM   qualified , totals;