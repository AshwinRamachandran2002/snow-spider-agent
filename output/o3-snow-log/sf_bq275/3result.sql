/* -------------------------------------------------------------
   Visitor IDs whose very first transaction happened on a device
   whose deviceCategory = 'mobile', and that transaction date is
   later than the date of their very first visit (any device).
----------------------------------------------------------------*/
WITH raw AS (          -- ❶  put all August-2016 sessions together
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160801
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160802
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160803
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160804
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160805
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160806
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160807
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160808
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160809
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160810
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160811
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160812
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160813
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160814
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160815
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160816
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160817
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160818
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160819
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160820
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160821
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160822
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160823
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160824
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160825
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160826
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160827
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160828
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160829
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160830
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160831
),

sessions AS (          -- ❷  extract the fields we need
    SELECT
        "fullVisitorId"                                           AS visitor_id,
        TO_DATE("date",'YYYYMMDD')                                AS session_dt,
        ("totals":"totalTransactionRevenue")::NUMBER              AS txn_revenue,
        ("device":"deviceCategory")::STRING                       AS device_category
    FROM raw
),

user_level AS (        -- ❸  first visit / first (mobile) transaction per user
    SELECT
        visitor_id,
        MIN(session_dt)                                                               AS first_visit_dt,
        MIN(CASE WHEN txn_revenue IS NOT NULL AND txn_revenue > 0 
                 THEN session_dt END)                                                 AS first_txn_dt,
        MIN(CASE WHEN txn_revenue IS NOT NULL AND txn_revenue > 0 
                     AND device_category = 'mobile'
                 THEN session_dt END)                                                 AS first_mobile_txn_dt
    FROM sessions
    GROUP BY visitor_id
)

SELECT  visitor_id
FROM    user_level
WHERE   first_txn_dt        = first_mobile_txn_dt        -- first transaction was on mobile
  AND   first_mobile_txn_dt > first_visit_dt             -- occurred after first ever visit
  AND   first_mobile_txn_dt IS NOT NULL;                 -- ensure a qualifying txn exists