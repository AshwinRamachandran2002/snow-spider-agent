/*-----------------------------------------------------------
   Visitors’ time-to-first-purchase and device used
   (February-2017 sessions only)
  -----------------------------------------------------------*/
WITH feb_sessions AS (
    /* identical column list for every daily table --------- */
    SELECT "fullVisitorId"                                       AS visitor_id ,
           TO_DATE("date",'YYYYMMDD')                            AS session_date ,
           TO_NUMBER("totals":"transactions")                    AS transactions ,
           "device":"deviceCategory"::STRING                     AS device_category ,
           "visitStartTime"                                      AS visit_start_ts
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170201

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170202

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170203

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170204

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170205

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170206

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170207

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170208

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170209

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170210

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170211

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170212

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170213

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170214

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170215

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170216

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170217

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170218

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170219

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170220

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170221

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170222

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170223

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170224

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170225

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170226

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170227

    UNION ALL SELECT "fullVisitorId",
                     TO_DATE("date",'YYYYMMDD'),
                     TO_NUMBER("totals":"transactions"),
                     "device":"deviceCategory"::STRING,
                     "visitStartTime"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170228
),

/* first visit and first transaction dates (within Feb-2017) */
visitor_firsts AS (
    SELECT
        visitor_id,
        MIN(session_date)                                       AS first_visit_date,
        MIN(CASE WHEN transactions > 0 THEN session_date END)   AS first_transaction_date
    FROM feb_sessions
    GROUP BY visitor_id
),

/* device used in the first February transaction */
device_first AS (
    SELECT visitor_id, device_category
    FROM (
        SELECT
            visitor_id,
            device_category,
            ROW_NUMBER() OVER (PARTITION BY visitor_id
                               ORDER BY session_date, visit_start_ts) AS rn
        FROM feb_sessions
        WHERE transactions > 0
    )
    WHERE rn = 1
)

/* final result ------------------------------------------------*/
SELECT
      vf.visitor_id                                                    AS "FULLVISITORID",
      DATEDIFF('day',
               vf.first_visit_date,
               vf.first_transaction_date)                              AS "DAYS_TO_FIRST_PURCHASE",
      df.device_category                                               AS "DEVICE_OF_FIRST_PURCHASE"
FROM   visitor_firsts vf
JOIN   device_first  df
  ON   vf.visitor_id = df.visitor_id
WHERE  vf.first_transaction_date IS NOT NULL
ORDER  BY "DAYS_TO_FIRST_PURCHASE", "FULLVISITORID";