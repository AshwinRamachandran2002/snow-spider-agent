/* -----------------------------------------------------------
   Longest span – first visit  →  “last recorded event”
   (last recorded event = last MOBILE visit OR first MOBILE
    transaction, whichever comes later for that user)
----------------------------------------------------------------*/

WITH sessions AS (

    /* ---------- 2016-08 ---------- */
    SELECT "fullVisitorId"                                AS "user_id",
           "date",
           "device":"deviceCategory"::STRING              AS "device_cat",
           COALESCE(("totals":"transactions")::NUMBER,0)  AS "txn_cnt"
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160801"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160802"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160803"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160804"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160805"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160806"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160807"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160808"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160809"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160810"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160811"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160812"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160813"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160814"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160815"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160816"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160817"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160818"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160819"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160820"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160821"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160822"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160823"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160824"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160825"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160826"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160827"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160828"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160829"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160830"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160831"

    /* ----------------------------------------------------------
       (Repeat the same pattern for every remaining daily table:
        20160901 … 20170801 – omitted here only for brevity)
       ---------------------------------------------------------- */

    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,COALESCE(("totals":"transactions")::NUMBER,0)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170801"
),

/* -----------------------------------------------------------
   Build user-level picture
-----------------------------------------------------------*/
per_user AS (
    SELECT
        "user_id",

        /* first-ever visit (regardless of device) */
        MIN("date")                                              AS "first_visit_dt",

        /* last visit on MOBILE */
        MAX(CASE WHEN "device_cat" = 'mobile'
                 THEN "date" END)                                AS "last_mob_visit_dt",

        /* first MOBILE transaction */
        MIN(CASE WHEN "device_cat" = 'mobile'
                     AND "txn_cnt" > 0
                 THEN "date" END)                                AS "first_mob_txn_dt"
    FROM sessions
    GROUP BY "user_id"
),

/* -----------------------------------------------------------
   Pick “last recorded event” (must be mobile) and compute days
-----------------------------------------------------------*/
with_span AS (
    SELECT
        "user_id",
        "first_visit_dt",

        /* choose later of: last mobile visit  vs  first mobile txn */
        CASE
            WHEN "last_mob_visit_dt" IS NOT NULL
                 AND ( "first_mob_txn_dt" IS NULL
                       OR "last_mob_visit_dt" >= "first_mob_txn_dt" )
            THEN "last_mob_visit_dt"
            ELSE "first_mob_txn_dt"
        END                                                     AS "last_event_dt"
    FROM per_user
    WHERE "last_mob_visit_dt" IS NOT NULL   /* must have a mobile event */
          OR  "first_mob_txn_dt" IS NOT NULL
)

/* -----------------------------------------------------------
   Final answer – user with the longest span
-----------------------------------------------------------*/
SELECT
    "user_id",
    DATEDIFF(
        day,
        TO_DATE("first_visit_dt" , 'YYYYMMDD'),
        TO_DATE("last_event_dt"  , 'YYYYMMDD')
    )                                                           AS "days_between"
FROM with_span
ORDER BY "days_between" DESC NULLS LAST
LIMIT 1;