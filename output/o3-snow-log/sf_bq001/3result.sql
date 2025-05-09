/*-----------------------------------------------
   First-transaction lag & device (Feb-2017)
------------------------------------------------*/
WITH feb_sessions AS (

    /* 01 Feb 2017 */
    SELECT
        "fullVisitorId"                                        AS visitor_id ,
        "date"                                                 AS date_txt  ,
        TO_DATE("date",'YYYYMMDD')                             AS session_date ,
        "visitStartTime"::INTEGER                              AS visit_start_time ,
        ("totals":"transactions")::NUMBER                      AS transactions ,
        ("device":"deviceCategory")::STRING                    AS device_category
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170201
    
    UNION ALL    /* 02 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170202
    
    UNION ALL    /* 03 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170203
    
    UNION ALL    /* 04 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170204
    
    UNION ALL    /* 05 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170205
    
    UNION ALL    /* 06 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170206
    
    UNION ALL    /* 07 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170207
    
    UNION ALL    /* 08 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170208
    
    UNION ALL    /* 09 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170209
    
    UNION ALL    /* 10 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170210
    
    UNION ALL    /* 11 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170211
    
    UNION ALL    /* 12 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170212
    
    UNION ALL    /* 13 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170213
    
    UNION ALL    /* 14 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170214
    
    UNION ALL    /* 15 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170215
    
    UNION ALL    /* 16 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170216
    
    UNION ALL    /* 17 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170217
    
    UNION ALL    /* 18 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170218
    
    UNION ALL    /* 19 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170219
    
    UNION ALL    /* 20 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170220
    
    UNION ALL    /* 21 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170221
    
    UNION ALL    /* 22 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170222
    
    UNION ALL    /* 23 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170223
    
    UNION ALL    /* 24 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170224
    
    UNION ALL    /* 25 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170225
    
    UNION ALL    /* 26 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170226
    
    UNION ALL    /* 27 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170227
    
    UNION ALL    /* 28 Feb 2017 */
    SELECT
        "fullVisitorId",
        "date",
        TO_DATE("date",'YYYYMMDD'),
        "visitStartTime"::INTEGER,
        ("totals":"transactions")::NUMBER,
        ("device":"deviceCategory")::STRING
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170228
),

/* first visit & first-transaction dates per visitor */
first_dates AS (
    SELECT
        visitor_id,
        MIN(session_date)                                           AS first_visit_date ,
        MIN(CASE WHEN transactions > 0 THEN session_date END)       AS first_txn_date
    FROM feb_sessions
    GROUP BY visitor_id
    HAVING first_txn_date IS NOT NULL          -- keep only visitors with ≥1 transaction
),

/* device used for that very first transaction */
first_txn_device AS (
    SELECT
        fs.visitor_id ,
        fs.device_category ,
        ROW_NUMBER() OVER (PARTITION BY fs.visitor_id
                           ORDER BY fs.session_date , fs.visit_start_time) AS rn
    FROM feb_sessions fs
    JOIN first_dates fd
      ON  fs.visitor_id   = fd.visitor_id
     AND fs.session_date  = fd.first_txn_date
     AND fs.transactions  > 0
)
SELECT
    fd.visitor_id ,
    DATEDIFF('day', fd.first_visit_date, fd.first_txn_date)  AS days_until_first_transaction ,
    ftd.device_category                                      AS device_type_first_transaction
FROM first_dates      fd
JOIN first_txn_device ftd
  ON fd.visitor_id = ftd.visitor_id
WHERE ftd.rn = 1                -- pick the earliest txn session if more than one per day
ORDER BY fd.visitor_id;