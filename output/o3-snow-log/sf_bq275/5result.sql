/*  Visitor IDs whose very first transaction was
    (a) done on a session coming from a device whose "deviceCategory" = 'mobile'
    (b) and happened strictly after their very first visit                */

WITH sessions AS (

    /* ------------------------------------------------------------------
       UNION every August-2016 daily session table from the GA sample set
       ------------------------------------------------------------------ */
    SELECT  "fullVisitorId"                                  AS visitor_id ,
            TO_DATE("date",'YYYYMMDD')                       AS session_date ,
            "visitStartTime"                                 AS session_ts ,
            COALESCE("totals":"transactions"::NUMBER ,0)     AS transactions ,
            LOWER("device":"deviceCategory"::STRING)         AS device_category
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160801  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160802  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160803  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160804  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160805  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160806  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160807  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160808  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160809  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160810  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160811  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160812  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160813  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160814  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160815  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160816  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160817  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160818  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160819  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160820  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160821  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160822  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160823  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160824  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160825  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160826  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160827  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160828  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160829  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160830  UNION ALL
    SELECT  "fullVisitorId", TO_DATE("date",'YYYYMMDD'), "visitStartTime",
            COALESCE("totals":"transactions"::NUMBER ,0),
            LOWER("device":"deviceCategory"::STRING)
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160831
),

/* pick the very first *transaction* session for every visitor --------- */
first_txn AS (
    SELECT  visitor_id ,
            device_category ,
            session_ts
    FROM   (
        SELECT visitor_id ,
               device_category ,
               session_ts ,
               ROW_NUMBER() OVER (PARTITION BY visitor_id ORDER BY session_ts) AS rn
        FROM   sessions
        WHERE  transactions > 0
    )
    WHERE  rn = 1
),

/* pick the very first session of any kind for every visitor ----------- */
first_visit AS (
    SELECT  visitor_id ,
            MIN(session_ts) AS first_visit_ts
    FROM    sessions
    GROUP BY visitor_id
)

/* --------------------------- final answer --------------------------- */
SELECT  DISTINCT ftx.visitor_id
FROM    first_txn   AS ftx
JOIN    first_visit AS fv
       ON ftx.visitor_id = fv.visitor_id
WHERE   ftx.device_category = 'mobile'   -- first purchase made on mobile
  AND   ftx.session_ts    > fv.first_visit_ts   -- and after first visit
ORDER BY ftx.visitor_id;