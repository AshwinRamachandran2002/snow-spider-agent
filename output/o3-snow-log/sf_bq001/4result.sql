/*  Days between first visit in February-2017 and first transaction in February-2017,
    together with the device category used for that first transaction               */

WITH feb_sessions AS (      -- all February-2017 sessions
    SELECT
        "fullVisitorId"                                            AS visitor_id ,
        TO_DATE("date",'YYYYMMDD')                                 AS session_date ,
        COALESCE(("totals":"transactions")::NUMBER ,0)             AS transactions ,
        ("device":"deviceCategory")::STRING                        AS device_category
    FROM (   -- explicit UNION of every daily table in Feb-2017
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170201 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170202 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170203 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170204 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170205 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170206 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170207 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170208 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170209 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170210 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170211 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170212 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170213 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170214 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170215 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170216 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170217 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170218 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170219 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170220 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170221 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170222 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170223 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170224 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170225 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170226 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170227 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170228
    )
),
firsts AS (                 -- first visit date & first transaction date in Feb-2017
    SELECT
        visitor_id,
        MIN(session_date)                                                AS first_visit_date,
        MIN(CASE WHEN transactions > 0 THEN session_date END)            AS first_trans_date
    FROM feb_sessions
    GROUP BY visitor_id
    HAVING first_trans_date IS NOT NULL          -- keep only visitors who transacted
),
trans_device AS (           -- device used on the first-transaction day
    SELECT
        f.visitor_id,
        f.first_visit_date,
        f.first_trans_date,
        MIN(fs.device_category)                        AS device_category   -- any device on that day
    FROM firsts         f
    JOIN feb_sessions   fs
          ON fs.visitor_id   = f.visitor_id
         AND fs.transactions > 0
         AND fs.session_date = f.first_trans_date
    GROUP BY f.visitor_id, f.first_visit_date, f.first_trans_date
)
SELECT
    visitor_id,
    DATEDIFF(day , first_visit_date , first_trans_date)   AS days_elapsed ,
    device_category
FROM trans_device
ORDER BY days_elapsed NULLS LAST , visitor_id;