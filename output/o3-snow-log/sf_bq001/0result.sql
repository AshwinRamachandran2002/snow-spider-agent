WITH feb_sessions AS (  
    SELECT  
        "fullVisitorId"::STRING                        AS fullVisitorId ,  
        "date"::STRING                                 AS date_str ,  
        TO_DATE("date",'YYYYMMDD')                     AS visit_date ,  
        ("totals":"transactions")::NUMBER              AS transactions ,  
        ("device":"deviceCategory")::STRING            AS device_category  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170201  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170202  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170203  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170204  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170205  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170206  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170207  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170208  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170209  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170210  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170211  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170212  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170213  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170214  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170215  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170216  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170217  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170218  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170219  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170220  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170221  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170222  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170223  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170224  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170225  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170226  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170227  

    UNION ALL SELECT  
        "fullVisitorId", "date", TO_DATE("date",'YYYYMMDD'),  
        ("totals":"transactions")::NUMBER,  
        ("device":"deviceCategory")::STRING  
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170228  
),  

per_visitor AS (  
    SELECT  
        fullVisitorId ,  
        MIN(visit_date)                                              AS first_visit_date ,  
        MIN(CASE WHEN transactions > 0 THEN visit_date END)          AS first_trans_date  
    FROM feb_sessions  
    GROUP BY fullVisitorId  
    HAVING first_trans_date IS NOT NULL         -- keep only visitors with at least one transaction  
)  

SELECT  
    v.fullVisitorId ,  
    DATEDIFF('day', v.first_visit_date, v.first_trans_date)          AS days_until_first_transaction ,  
    MIN(s.device_category)                                           AS device_category_first_transaction  
FROM per_visitor          v  
JOIN feb_sessions         s  
      ON  s.fullVisitorId = v.fullVisitorId  
      AND s.visit_date    = v.first_trans_date  
      AND s.transactions  > 0  
GROUP BY  
    v.fullVisitorId ,  
    v.first_visit_date ,  
    v.first_trans_date  
ORDER BY v.fullVisitorId;