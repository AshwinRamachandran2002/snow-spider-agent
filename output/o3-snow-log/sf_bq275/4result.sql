/* 1. Bring together every August-2016 session table                            */
WITH all_sessions AS (
    SELECT * FROM (
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
    )
),

/* 2. Keep only the fields we need                                              */
sessions AS (
    SELECT
        "fullVisitorId"                                            AS visitor_id,
        "visitStartTime"                                           AS visit_start_time,
        TO_DATE("date", 'YYYYMMDD')                                AS session_date,
        TRY_TO_NUMBER( ("totals":"totalTransactionRevenue")::STRING ) AS txn_revenue,
        LOWER( ("device":"deviceCategory")::STRING )               AS device_category
    FROM all_sessions
),

/* 3. Determine first visit and first transaction timestamps per visitor        */
firsts AS (
    SELECT
        visitor_id,
        MIN(visit_start_time)                                                         AS first_visit_ts,
        MIN(CASE WHEN txn_revenue IS NOT NULL AND txn_revenue > 0 
                 THEN visit_start_time END)                                           AS first_txn_ts
    FROM sessions
    GROUP BY visitor_id
),

/* 4. Capture the device category used in the first transaction                 */
first_txn_device AS (
    SELECT
        s.visitor_id,
        s.device_category
    FROM sessions s
    JOIN firsts  f
      ON s.visitor_id      = f.visitor_id
     AND s.visit_start_time = f.first_txn_ts
)

/* 5. Final answer                                                             */
SELECT DISTINCT f.visitor_id
FROM   firsts            f
JOIN   first_txn_device  d USING (visitor_id)
WHERE  f.first_txn_ts IS NOT NULL            -- visitor has a transaction
  AND  f.first_txn_ts > f.first_visit_ts     -- transaction occurred after first visit
  AND  d.device_category = 'mobile'          -- device category is explicitly 'mobile'
ORDER BY f.visitor_id;