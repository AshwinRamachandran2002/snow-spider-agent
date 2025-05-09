/*  Days between a visitor's first February-2017 visit and their first
    February-2017 transaction, plus the device category used for that
    first transaction                                                    */

WITH all_feb AS (      -- full set of Feb-2017 session rows
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170201
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170202
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170203
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170204
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170205
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170206
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170207
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170208
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170209
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170210
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170211
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170212
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170213
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170214
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170215
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170216
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170217
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170218
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170219
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170220
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170221
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170222
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170223
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170224
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170225
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170226
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170227
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170228
),
feb_sessions AS (      -- pull only the columns we need
    SELECT
        "fullVisitorId"                                            AS visitor_id ,
        TO_DATE("date",'YYYYMMDD')                                  AS session_date ,
        ("totals":"transactions")::INTEGER                          AS transactions ,
        ("device":"deviceCategory")::STRING                         AS device_category
    FROM all_feb
),
visitor_marks AS (     -- first Feb visit date & first Feb transaction date
    SELECT
        visitor_id ,
        MIN(session_date)                                                AS first_visit_date ,
        MIN(CASE WHEN transactions > 0 THEN session_date END)            AS first_trans_date
    FROM feb_sessions
    GROUP BY visitor_id
),
first_trans_device AS ( -- device used in the first transaction
    SELECT
        fs.visitor_id ,
        fs.device_category ,
        ROW_NUMBER() OVER (PARTITION BY fs.visitor_id
                           ORDER BY fs.session_date)                     AS rn
    FROM feb_sessions fs
    JOIN visitor_marks vm
      ON fs.visitor_id   = vm.visitor_id
     AND fs.transactions > 0
     AND fs.session_date = vm.first_trans_date
)
SELECT
    vm.visitor_id ,
    DATEDIFF(day, vm.first_visit_date , vm.first_trans_date)  AS days_elapsed ,
    ftd.device_category                                        AS first_transaction_device
FROM visitor_marks      vm
JOIN first_trans_device ftd
  ON vm.visitor_id = ftd.visitor_id
WHERE vm.first_trans_date IS NOT NULL    -- keep only visitors who transacted
  AND ftd.rn = 1                         -- exactly one row per visitor
ORDER BY days_elapsed DESC NULLS LAST ,
         vm.visitor_id ;