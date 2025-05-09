/*-----------------------------------------------------------
  Find the user-id(s) that exhibit the longest span (in days) 
  between their very first visit and their final recorded event
  (last visit OR first transaction), where that final event
  happened on a mobile device.
-----------------------------------------------------------*/
WITH per_user AS (          -- first-visit / last-visit / first-transaction
    SELECT
        "fullVisitorId",
        MIN("visitStartTime")                                                AS first_visit_ts,
        MAX("visitStartTime")                                                AS last_visit_ts,
        MIN(CASE WHEN ("totals":"transactions")::NUMBER > 0 
                 THEN "visitStartTime" END)                                  AS first_txn_ts
    FROM   GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160801"
    GROUP  BY "fullVisitorId"
), last_event AS (         -- choose whichever is the later: last visit vs. first txn
    SELECT
        pu.*,
        GREATEST(pu.last_visit_ts , COALESCE(pu.first_txn_ts ,0))            AS last_recorded_ts
    FROM   per_user pu
), mobile_only AS (        -- keep visitors whose last-recorded event was mobile
    SELECT
        le."fullVisitorId",
        le.first_visit_ts,
        le.last_recorded_ts,
        ROUND( (le.last_recorded_ts - le.first_visit_ts) / 86400 , 2)        AS days_between
    FROM   last_event le
    WHERE  EXISTS ( SELECT 1
                    FROM   GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160801" s
                    WHERE  s."fullVisitorId"      = le."fullVisitorId"
                      AND  s."visitStartTime"     = le.last_recorded_ts
                      AND  s."device":"isMobile"::BOOLEAN = TRUE )
), max_span AS (          -- longest span (in days)
    SELECT  MAX(days_between) AS max_days_between
    FROM    mobile_only
)
SELECT
       m."fullVisitorId",
       m.days_between        AS longest_days_between
FROM   mobile_only m
JOIN   max_span      x
  ON   m.days_between = x.max_days_between
ORDER  BY m."fullVisitorId";