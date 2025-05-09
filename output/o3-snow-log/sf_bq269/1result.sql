WITH sessions AS (   /* collect every session from 1-Jun-2017 through 31-Jul-2017 */
    SELECT "fullVisitorId"      AS visitor_id ,
           "totals"             AS totals      ,
           "date"               AS date_str
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170601
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170602
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170603
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170604
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170605
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170606
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170607
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170608
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170609
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170610
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170611
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170612
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170613
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170614
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170615
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170616
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170617
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170618
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170619
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170620
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170621
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170622
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170623
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170624
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170625
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170626
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170627
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170628
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170629
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170630
    /* ------------------------------  JULY  -------------------------------- */
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170702
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170703
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170704
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170705
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170706
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170707
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170708
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170709
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170710
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170711
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170712
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170713
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170714
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170715
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170716
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170717
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170718
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170719
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170720
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170721
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170722
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170723
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170724
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170725
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170726
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170727
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170728
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170729
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170730
    UNION ALL SELECT "fullVisitorId","totals","date" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170731
),

filtered AS (  /* keep only sessions that have pageviews */
    SELECT
        visitor_id ,
        totals:"pageviews"::NUMBER                   AS pageviews ,
        COALESCE(totals:"transactions"::NUMBER, 0)   AS transactions ,
        TO_DATE(date_str,'YYYYMMDD')                 AS session_date
    FROM sessions
    WHERE totals:"pageviews" IS NOT NULL
          AND TO_DATE(date_str,'YYYYMMDD')
                BETWEEN '2017-06-01' AND '2017-07-31'
),

classified AS (  /* classify each session */
    SELECT
        DATE_TRUNC('month', session_date)                               AS month ,
        visitor_id ,
        CASE WHEN transactions > 0 THEN 'purchase'
             ELSE 'non_purchase' END                                    AS class ,
        pageviews
    FROM filtered
),

visitor_totals AS (  /* sum pageviews per visitor & class each month */
    SELECT
        month ,
        visitor_id ,
        class ,
        SUM(pageviews) AS visitor_pageviews
    FROM classified
    GROUP BY month , visitor_id , class
),

month_avgs AS (  /* average pageviews per visitor for every class */
    SELECT
        month ,
        AVG(CASE WHEN class = 'purchase'     THEN visitor_pageviews END)
            AS avg_pageviews_purchase ,
        AVG(CASE WHEN class = 'non_purchase' THEN visitor_pageviews END)
            AS avg_pageviews_non_purchase
    FROM visitor_totals
    GROUP BY month
)

SELECT
    TO_CHAR(month,'YYYY-MM')                         AS month ,
    ROUND(avg_pageviews_purchase     , 4)            AS avg_pageviews_purchase ,
    ROUND(avg_pageviews_non_purchase , 4)            AS avg_pageviews_non_purchase
FROM month_avgs
ORDER BY month;