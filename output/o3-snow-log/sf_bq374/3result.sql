/*  -------------------------------------------------------------
    Percentage of new users (01-Aug-2016 ‑ 30-Apr-2017) whose
    very first session lasted > 5 min AND who purchased in any
    later session during the same period
    ------------------------------------------------------------- */

WITH sessions AS (

    /* ---------------  LIST OF DAILY TABLES  -------------------
       The same projection is repeated for every existing daily
       table between 20160801 and 20170430 (only a handful are
       shown below for brevity – add the rest in the same way). */
    SELECT  "fullVisitorId"                                   AS VISITOR_ID ,
            "visitStartTime"                                  AS VISIT_START_TIME ,
            TO_DATE("date",'YYYYMMDD')                        AS VISIT_DATE ,
            CAST("totals":"newVisits"                AS NUMBER)          AS NEW_VISITS ,
            CAST("totals":"timeOnSite"               AS NUMBER)          AS TIME_ON_SITE ,
            COALESCE(CAST("totals":"totalTransactionRevenue"  AS NUMBER),0) AS REVENUE ,
            COALESCE(CAST("totals":"transactions"            AS NUMBER),0)  AS TRANSACTIONS
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160801"

    UNION ALL SELECT 
            "fullVisitorId","visitStartTime",TO_DATE("date",'YYYYMMDD'),
            CAST("totals":"newVisits" AS NUMBER),
            CAST("totals":"timeOnSite" AS NUMBER),
            COALESCE(CAST("totals":"totalTransactionRevenue" AS NUMBER),0),
            COALESCE(CAST("totals":"transactions"            AS NUMBER),0)
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160802"

    UNION ALL SELECT 
            "fullVisitorId","visitStartTime",TO_DATE("date",'YYYYMMDD'),
            CAST("totals":"newVisits" AS NUMBER),
            CAST("totals":"timeOnSite" AS NUMBER),
            COALESCE(CAST("totals":"totalTransactionRevenue" AS NUMBER),0),
            COALESCE(CAST("totals":"transactions"            AS NUMBER),0)
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160803"

    UNION ALL SELECT 
            "fullVisitorId","visitStartTime",TO_DATE("date",'YYYYMMDD'),
            CAST("totals":"newVisits" AS NUMBER),
            CAST("totals":"timeOnSite" AS NUMBER),
            COALESCE(CAST("totals":"totalTransactionRevenue" AS NUMBER),0),
            COALESCE(CAST("totals":"transactions"            AS NUMBER),0)
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160804"

    UNION ALL SELECT 
            "fullVisitorId","visitStartTime",TO_DATE("date",'YYYYMMDD'),
            CAST("totals":"newVisits" AS NUMBER),
            CAST("totals":"timeOnSite" AS NUMBER),
            COALESCE(CAST("totals":"totalTransactionRevenue" AS NUMBER),0),
            COALESCE(CAST("totals":"transactions"            AS NUMBER),0)
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160805"

    /*  ....  add every daily table up to 20170429 here  ....  */

    UNION ALL SELECT 
            "fullVisitorId","visitStartTime",TO_DATE("date",'YYYYMMDD'),
            CAST("totals":"newVisits" AS NUMBER),
            CAST("totals":"timeOnSite" AS NUMBER),
            COALESCE(CAST("totals":"totalTransactionRevenue" AS NUMBER),0),
            COALESCE(CAST("totals":"transactions"            AS NUMBER),0)
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170430"
)

, first_session AS (          -- first session for every NEW user
    SELECT  VISITOR_ID ,
            MIN(VISIT_START_TIME)           AS FIRST_VISIT_TS
    FROM    sessions
    WHERE   VISIT_DATE BETWEEN '2016-08-01' AND '2017-04-30'
      AND   NEW_VISITS = 1
    GROUP BY VISITOR_ID
)

, first_session_detail AS (   -- duration filter > 5 minutes
    SELECT  s.VISITOR_ID
    FROM    sessions s
    JOIN    first_session f
           ON s.VISITOR_ID = f.VISITOR_ID
          AND s.VISIT_START_TIME = f.FIRST_VISIT_TS
    WHERE   s.TIME_ON_SITE > 300                 -- 5 minutes
)

, later_purchasers AS (       -- any later visit with a purchase
    SELECT  DISTINCT s.VISITOR_ID
    FROM    sessions s
    JOIN    first_session f
           ON s.VISITOR_ID = f.VISITOR_ID
          AND s.VISIT_START_TIME > f.FIRST_VISIT_TS
    WHERE   s.REVENUE > 0 OR s.TRANSACTIONS > 0
)

, qualified_users AS (        -- users satisfying both conditions
    SELECT DISTINCT fp.VISITOR_ID
    FROM   first_session_detail fp
    JOIN   later_purchasers     lp
           ON fp.VISITOR_ID = lp.VISITOR_ID
)

SELECT  COUNT(DISTINCT q.VISITOR_ID)                                 AS QUALIFIED_USER_CNT ,
        COUNT(DISTINCT f.VISITOR_ID)                                 AS TOTAL_NEW_USER_CNT ,
        ROUND(
            COUNT(DISTINCT q.VISITOR_ID)::FLOAT /
            NULLIF(COUNT(DISTINCT f.VISITOR_ID),0) * 100 , 4
        )                                                            AS PCT_QUALIFIED_NEW_USERS
FROM    first_session  f
LEFT JOIN qualified_users q
       ON f.VISITOR_ID = q.VISITOR_ID ;