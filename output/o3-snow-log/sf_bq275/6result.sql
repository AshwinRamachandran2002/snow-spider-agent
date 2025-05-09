/*  Visitor IDs whose very first transaction happened
    (1) on a device whose category is explicitly “mobile”, and
    (2) strictly after their very first visit                                         */

WITH all_days AS (          /* ---------- UNION ALL the August-2016 session tables ---------- */
    SELECT * FROM (
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160801 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160802 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160803 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160804 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160805 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160806 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160807 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160808 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160809 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160810 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160811 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160812 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160813 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160814 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160815 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160816 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160817 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160818 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160819 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160820 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160821 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160822 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160823 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160824 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160825 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160826 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160827 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160828 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160829 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160830 UNION ALL
        SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160831
    )
),

sessions AS (               /* ---------- pick only the columns we need -------------------- */
    SELECT
        "fullVisitorId"                               AS visitor_id,
        "visitStartTime"::NUMBER                      AS visit_ts,
        ("totals":"totalTransactionRevenue")::NUMBER  AS revenue,
        LOWER(("device":"deviceCategory")::STRING)    AS device_category
    FROM all_days
),

first_visit AS (            /* ---------- first ever session per visitor ------------------- */
    SELECT
        visitor_id,
        MIN(visit_ts) AS first_visit_ts
    FROM sessions
    GROUP BY visitor_id
),

first_txn AS (              /* ---------- first ever transaction per visitor --------------- */
    SELECT
        visitor_id,
        MIN(visit_ts) AS first_txn_ts
    FROM sessions
    WHERE revenue IS NOT NULL
    GROUP BY visitor_id
),

first_txn_device AS (       /* ---------- device used for that first transaction ----------- */
    SELECT
        s.visitor_id,
        s.device_category
    FROM sessions s
    JOIN first_txn ft
      ON  s.visitor_id = ft.visitor_id
     AND s.visit_ts   = ft.first_txn_ts
)

SELECT DISTINCT
       ftd.visitor_id
FROM first_txn_device ftd
JOIN first_visit fv ON fv.visitor_id = ftd.visitor_id
JOIN first_txn  ft ON ft.visitor_id = ftd.visitor_id
WHERE ftd.device_category = 'mobile'          -- transaction done on a mobile device
  AND ft.first_txn_ts  > fv.first_visit_ts    -- after their very first visit
ORDER BY ftd.visitor_id;