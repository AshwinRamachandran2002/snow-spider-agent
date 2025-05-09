/* -------------------------------------------------------------------------
   Average pageviews per visitor for purchase vs. non-purchase sessions
   (June 1 – July 31 2017)
---------------------------------------------------------------------------*/
WITH union_sessions AS (   ------------------------------------------------------------------
    /* Restrict every branch to the same three columns to avoid UNION errors */
    /* ------------------------------  JUNE 2017  --------------------------- */
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170601 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170602 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170603 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170604 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170605 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170606 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170607 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170608 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170609 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170610 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170611 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170612 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170613 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170614 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170615 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170616 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170617 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170618 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170619 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170620 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170621 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170622 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170623 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170624 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170625 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170626 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170627 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170628 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170629 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170630 UNION ALL

    /* ------------------------------  JULY 2017  --------------------------- */
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170702 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170703 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170704 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170705 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170706 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170707 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170708 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170709 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170710 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170711 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170712 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170713 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170714 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170715 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170716 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170717 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170718 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170719 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170720 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170721 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170722 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170723 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170724 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170725 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170726 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170727 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170728 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170729 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170730 UNION ALL
    SELECT "date","fullVisitorId","totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170731
),  --------------------------------------------------------------------------

filtered_sessions AS (
    SELECT
        TO_DATE("date",'YYYYMMDD')                    AS session_date,
        "fullVisitorId"                               AS visitor_id,
        ("totals":"pageviews")::NUMBER                AS pageviews,
        CASE
            WHEN COALESCE(("totals":"transactions")::NUMBER,0) >= 1
                 THEN 'purchase'
            ELSE 'non_purchase'
        END                                           AS session_type
    FROM union_sessions
    WHERE ("totals":"pageviews") IS NOT NULL
),

visitor_monthly AS (
    SELECT
        DATE_TRUNC('month', session_date)  AS month_start,
        visitor_id,
        session_type,
        SUM(pageviews)                     AS total_pageviews
    FROM filtered_sessions
    GROUP BY 1,2,3
)

SELECT
    TO_CHAR(month_start,'YYYY-MM')                                    AS month,
    AVG(CASE WHEN session_type = 'purchase'     THEN total_pageviews END)
        AS avg_pageviews_purchase,
    AVG(CASE WHEN session_type = 'non_purchase' THEN total_pageviews END)
        AS avg_pageviews_non_purchase
FROM visitor_monthly
GROUP BY month_start
ORDER BY month_start;