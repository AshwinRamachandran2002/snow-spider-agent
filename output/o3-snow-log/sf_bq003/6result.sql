/* ------------------------------------------------------------------
   Average page-views per visitor – Purchase vs. Non-Purchase
   Period : 2017-04-01 → 2017-07-31        (Snowflake dialect)
-------------------------------------------------------------------*/
WITH union_sessions AS (      /* 1.  concatenate daily tables, keep needed cols */
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170401 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170402 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170403 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170404 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170405 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170406 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170407 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170408 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170409 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170410 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170411 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170412 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170413 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170414 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170415 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170416 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170417 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170418 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170419 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170420 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170421 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170422 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170423 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170424 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170425 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170426 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170427 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170428 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170429 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170430 UNION ALL
    /* -------------  MAY ------------- */
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170501 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170502 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170503 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170504 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170505 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170506 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170507 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170508 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170509 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170510 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170511 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170512 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170513 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170514 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170515 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170516 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170517 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170518 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170519 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170520 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170521 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170522 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170523 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170524 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170525 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170526 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170527 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170528 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170529 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170530 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170531 UNION ALL
    /* -------------  JUNE ------------- */
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170601 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170602 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170603 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170604 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170605 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170606 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170607 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170608 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170609 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170610 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170611 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170612 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170613 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170614 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170615 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170616 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170617 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170618 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170619 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170620 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170621 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170622 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170623 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170624 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170625 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170626 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170627 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170628 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170629 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170630 UNION ALL
    /* -------------  JULY ------------- */
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170702 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170703 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170704 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170705 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170706 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170707 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170708 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170709 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170710 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170711 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170712 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170713 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170714 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170715 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170716 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170717 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170718 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170719 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170720 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170721 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170722 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170723 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170724 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170725 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170726 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170727 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170728 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170729 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170730 UNION ALL
    SELECT "date","visitId","fullVisitorId","totals","hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170731
), /* ---------------------------------------------------------------- */
session_metrics AS (           /* 2.  derive metrics & purchase flag */
    SELECT
        TO_CHAR(TO_DATE("date",'YYYYMMDD'),'YYYY-MM')                    AS session_month,
        "fullVisitorId"                                                 AS visitor_id,
        "visitId"                                                       AS visit_id,
        MAX(TRY_TO_NUMBER(("totals":"pageviews")::STRING))              AS pageviews,
        MAX(TRY_TO_NUMBER(("totals":"transactions")::STRING))           AS transactions,
        MAX( CASE WHEN p.value:"productRevenue" IS NOT NULL THEN 1 ELSE 0 END )
                                                                        AS has_product_revenue
    FROM   union_sessions s,
           LATERAL FLATTEN(input => s."hits",   outer => TRUE)  h,
           LATERAL FLATTEN(input => h.value:"product", outer => TRUE) p
    GROUP  BY session_month, visitor_id, visit_id
), /* ---------------------------------------------------------------- */
classified AS (                /* 3.  flag sessions as Purchase / Non */
    SELECT
        session_month,
        visitor_id,
        COALESCE(pageviews,0)                                          AS pageviews,
        CASE
            WHEN transactions >= 1 AND has_product_revenue = 1 THEN 'Purchase'
            WHEN transactions IS NULL AND has_product_revenue = 0 THEN 'Non-Purchase'
            ELSE 'Other'
        END                                                            AS session_type
    FROM session_metrics
    WHERE session_type IN ('Purchase','Non-Purchase')
), /* ---------------------------------------------------------------- */
visitor_month AS (             /* 4.  aggregate to visitor-month      */
    SELECT
        session_month,
        visitor_id,
        session_type,
        SUM(pageviews) AS total_pageviews
    FROM   classified
    GROUP  BY session_month, visitor_id, session_type
)
/* ---------------------------- 5.  result --------------------------- */
SELECT
    session_month,
    session_type,
    AVG(total_pageviews) AS avg_pageviews_per_visitor
FROM   visitor_month
GROUP  BY session_month, session_type
ORDER  BY session_month, session_type;