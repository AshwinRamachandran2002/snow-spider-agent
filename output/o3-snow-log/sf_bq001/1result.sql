/*  Days between first February-2017 visit and first February-2017 transaction,
    together with the device category used for that first transaction            */

WITH feb_sessions AS (   -- all sessions that took place in February 2017
    SELECT
        "fullVisitorId"                                        AS fullVisitorId ,
        "visitId"                                              AS visitId      ,
        TO_DATE("date",'YYYYMMDD')                             AS session_date ,
        ("totals":"transactions")::INTEGER                     AS transactions ,
        ("device":"deviceCategory")::STRING                    AS device_category
    FROM (
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
    )
),

/* First February visit (whether or not a transaction occurred) */
first_visit AS (
    SELECT
        fullVisitorId,
        MIN(session_date) AS first_visit_date
    FROM feb_sessions
    GROUP BY fullVisitorId
),

/* First February transaction (only visitors who transacted)   */
first_txn AS (
    SELECT
        fullVisitorId,
        session_date      AS first_txn_date,
        device_category
    FROM (
        SELECT
            fullVisitorId,
            session_date,
            device_category,
            ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                               ORDER BY session_date, visitId) AS rn
        FROM feb_sessions
        WHERE transactions > 0
    )
    WHERE rn = 1      -- keep only the very first transaction per visitor
)

SELECT
    t.fullVisitorId                                                    AS visitor_id,
    DATEDIFF('day', v.first_visit_date, t.first_txn_date)              AS days_between_first_visit_and_first_txn,
    t.device_category                                                  AS first_txn_device_category
FROM first_txn  t
JOIN first_visit v
  ON t.fullVisitorId = v.fullVisitorId
ORDER BY visitor_id;