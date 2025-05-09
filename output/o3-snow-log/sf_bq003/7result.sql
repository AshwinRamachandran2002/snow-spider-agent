/*--------------------------------------------------------------------
  Average page-views per visitor for purchase vs. non-purchase sessions
  (April 1 – July 31, 2017)
--------------------------------------------------------------------*/
WITH union_raw AS (           -- 1. pull only the columns we need
    SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170401
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170402
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170403
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170404
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170405
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170406
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170407
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170408
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170409
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170410
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170411
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170412
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170413
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170414
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170415
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170416
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170417
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170418
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170419
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170420
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170421
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170422
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170423
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170424
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170425
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170426
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170427
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170428
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170429
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170430
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170501
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170502
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170503
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170504
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170505
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170506
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170507
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170508
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170509
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170510
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170511
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170512
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170513
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170514
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170515
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170516
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170517
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170518
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170519
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170520
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170521
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170522
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170523
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170524
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170525
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170526
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170527
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170528
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170529
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170530
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170531
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170601
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170602
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170603
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170604
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170605
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170606
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170607
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170608
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170609
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170610
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170611
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170612
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170613
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170614
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170615
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170616
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170617
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170618
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170619
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170620
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170621
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170622
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170623
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170624
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170625
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170626
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170627
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170628
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170629
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170630
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170702
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170703
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170704
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170705
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170706
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170707
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170708
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170709
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170710
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170711
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170712
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170713
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170714
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170715
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170716
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170717
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170718
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170719
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170720
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170721
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170722
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170723
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170724
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170725
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170726
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170727
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170728
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170729
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170730
 UNION ALL SELECT "fullVisitorId","visitId","date","totals","hits"  FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170731
),                                                        -- end union_raw
union_sessions AS (      -- 2. derive needed pieces
    SELECT
        "fullVisitorId"                                   AS fullVisitorId,
        "visitId"                                         AS visitId,
        "date"                                            AS date_str,
        TO_DATE("date",'YYYYMMDD')                        AS visit_date,
        "totals":pageviews::INTEGER                       AS pageviews,
        "totals":transactions::INTEGER                    AS transactions,
        "hits"                                            AS hits
    FROM union_raw
),                                                       -- end union_sessions
product_rev_sessions AS ( -- 3. sessions that contain product-level revenue
    SELECT DISTINCT
           s.fullVisitorId,
           s.visitId
    FROM   union_sessions s,
           LATERAL FLATTEN( INPUT => s.hits ) h,
           LATERAL FLATTEN( INPUT => h.value:product ) p
    WHERE  p.value:productRevenue IS NOT NULL
),                                                       -- end product_rev_sessions
classified_sessions AS (  -- 4. keep only clearly classified sessions
    SELECT
        s.fullVisitorId,
        s.visitId,
        DATE_TRUNC('month',s.visit_date)  AS month_start,
        s.pageviews,
        CASE
            WHEN s.transactions >= 1
                 AND prs.fullVisitorId IS NOT NULL THEN 'purchase'
            WHEN s.transactions IS NULL
                 AND prs.fullVisitorId IS NULL THEN 'non-purchase'
        END                         AS session_type
    FROM union_sessions s
    LEFT JOIN product_rev_sessions prs
           ON s.fullVisitorId = prs.fullVisitorId
          AND s.visitId       = prs.visitId
    WHERE (s.transactions >= 1  AND prs.fullVisitorId IS NOT NULL)
       OR (s.transactions IS NULL AND prs.fullVisitorId IS NULL)
),                                                       -- end classified_sessions
visitor_month_pageviews AS ( -- 5. sum pageviews per visitor & month
    SELECT
        month_start,
        session_type,
        fullVisitorId,
        SUM(pageviews) AS total_pageviews
    FROM classified_sessions
    GROUP BY month_start,session_type,fullVisitorId
),                                                       -- end visitor_month_pageviews
avg_pageviews AS (       -- 6. average page-views per visitor
    SELECT
        month_start,
        session_type,
        AVG(total_pageviews) AS avg_pageviews_per_visitor
    FROM visitor_month_pageviews
    GROUP BY month_start,session_type
)
-- 7. final result
SELECT
    TO_CHAR(month_start,'YYYY-MM')              AS month,
    session_type,
    ROUND(avg_pageviews_per_visitor,4)          AS avg_pageviews_per_visitor
FROM   avg_pageviews
ORDER  BY month_start, session_type;