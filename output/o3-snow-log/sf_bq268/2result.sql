/*  Longest gap (in days) between a visitor’s very first session and
    her/his last-recorded event (either the final session or the
    first transaction) – but only for visitors whose very last event
    occurred on a mobile or tablet device.                                    */

WITH sessions AS (
    /* Keep only the columns we actually need                                    */
    SELECT  "fullVisitorId",
            "visitStartTime",
            TO_DATE("date",'YYYYMMDD')                    AS session_date,
            "device":"deviceCategory"::STRING             AS device_cat,
            IFF("totals":"transactions" IS NOT NULL,1,0)  AS has_txn
    FROM    GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160801"
),

per_visitor AS (
    /* One record per visitor carrying the dates/timestamps we need              */
    SELECT  "fullVisitorId",
            MIN(session_date)                                                   AS first_visit_date,
            MAX(session_date)                                                   AS last_visit_date,
            MIN(IFF(has_txn = 1, session_date, NULL))                           AS first_txn_date,
            MAX("visitStartTime")                                               AS last_visit_ts
    FROM    sessions
    GROUP   BY "fullVisitorId"
),

last_event AS (
    /* Attach the device category of the visitor’s last session                  */
    SELECT  v."fullVisitorId",
            v.first_visit_date,
            GREATEST(v.last_visit_date, v.first_txn_date)      AS last_event_date,
            s.device_cat
    FROM    per_visitor          v
    JOIN    sessions             s
           ON  v."fullVisitorId" = s."fullVisitorId"
           AND v.last_visit_ts   = s."visitStartTime"
)

SELECT  MAX(DATEDIFF('day',
                     first_visit_date,
                     last_event_date))      AS longest_days_between
FROM    last_event
WHERE   device_cat ILIKE '%mobile%'          -- keep “mobile” device categories
    OR  device_cat ILIKE '%tablet%';         -- include tablets as well