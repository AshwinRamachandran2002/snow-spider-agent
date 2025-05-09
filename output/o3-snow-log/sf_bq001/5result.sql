WITH feb AS (      /* every February-2017 session */
    SELECT
        "fullVisitorId"::STRING                                           AS visitor_id ,
        TO_DATE("date",'YYYYMMDD')                                        AS session_date ,
        "visitStartTime"                                                  AS visit_start_time ,
        TRY_TO_NUMBER(("totals":"transactions")::STRING)                  AS transactions ,
        ("device":"deviceCategory")::STRING                               AS device_category
    FROM (
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
/* first February visit & first February transaction per visitor */
per_visitor AS (
    SELECT
        visitor_id,
        MIN(session_date)                                           AS first_visit_date,
        MIN(CASE WHEN transactions > 0 THEN session_date END)       AS first_trans_date
    FROM feb
    GROUP BY visitor_id
    HAVING first_trans_date IS NOT NULL
),
/* session that contains that first transaction to obtain device info */
first_trans_session AS (
    SELECT
        f.visitor_id,
        f.device_category,
        ROW_NUMBER() OVER (PARTITION BY f.visitor_id
                           ORDER BY f.session_date, f.visit_start_time) AS rn
    FROM feb f
    JOIN per_visitor p
      ON p.visitor_id   = f.visitor_id
     AND f.transactions > 0
     AND f.session_date = p.first_trans_date
)
SELECT
    p.visitor_id,
    DATEDIFF('day', p.first_visit_date, p.first_trans_date)
        AS days_between_first_visit_and_first_transaction,
    s.device_category  AS first_transaction_device
FROM per_visitor p
JOIN first_trans_session s
  ON p.visitor_id = s.visitor_id
WHERE s.rn = 1
ORDER BY days_between_first_visit_and_first_transaction,
         p.visitor_id;