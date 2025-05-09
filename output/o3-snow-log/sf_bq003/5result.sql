/* --------------------------------------------------------------------
   Average page-views per visitor (Apr-Jul 2017)
   • Purchase      : totals.transactions >= 1  AND any hits.product.productRevenue IS NOT NULL
   • Non-purchase  : totals.transactions IS NULL AND no productRevenue
---------------------------------------------------------------------*/
WITH all_sessions AS (   -- ----------  UNION ALL every daily table we need ----------
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170401 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170402 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170403 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170404 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170405 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170406 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170407 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170408 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170409 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170410 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170411 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170412 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170413 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170414 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170415 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170416 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170417 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170418 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170419 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170420 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170421 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170422 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170423 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170424 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170425 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170426 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170427 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170428 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170429 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170430 UNION ALL
    /* -----------------------------  MAY 2017  -----------------------------*/
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170501 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170502 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170503 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170504 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170505 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170506 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170507 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170508 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170509 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170510 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170511 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170512 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170513 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170514 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170515 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170516 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170517 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170518 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170519 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170520 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170521 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170522 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170523 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170524 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170525 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170526 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170527 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170528 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170529 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170530 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170531 UNION ALL
    /* -----------------------------  JUNE 2017  -----------------------------*/
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170601 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170602 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170603 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170604 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170605 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170606 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170607 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170608 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170609 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170610 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170611 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170612 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170613 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170614 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170615 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170616 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170617 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170618 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170619 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170620 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170621 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170622 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170623 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170624 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170625 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170626 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170627 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170628 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170629 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170630 UNION ALL
    /* -----------------------------  JULY 2017  -----------------------------*/
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170702 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170703 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170704 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170705 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170706 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170707 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170708 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170709 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170710 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170711 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170712 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170713 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170714 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170715 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170716 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170717 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170718 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170719 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170720 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170721 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170722 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170723 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170724 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170725 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170726 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170727 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170728 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170729 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170730 UNION ALL
    SELECT "fullVisitorId","visitId","date","totals","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170731
),
/* -----------------------------------------------------------------
   2.  Extract needed fields & cast numbers safely
------------------------------------------------------------------*/
base AS (
    SELECT
        "fullVisitorId"                     AS visitor_id,
        "visitId"                           AS visit_id,
        TO_DATE("date",'YYYYMMDD')          AS session_date,
        TRY_TO_NUMBER( ("totals":"pageviews")::STRING )      AS pageviews,
        TRY_TO_NUMBER( ("totals":"transactions")::STRING )  AS transactions,
        "hits"                              AS hits_variant
    FROM  all_sessions
    WHERE "date" BETWEEN '20170401' AND '20170731'
),
/* -----------------------------------------------------------------
   3.  Sessions that have any productRevenue
------------------------------------------------------------------*/
prod_rev_sessions AS (
    SELECT DISTINCT
           visitor_id,
           visit_id
    FROM   base,
           LATERAL FLATTEN(input => hits_variant)                hit,
           LATERAL FLATTEN(input => hit.value:"product")         pr
    WHERE  pr.value:"productRevenue" IS NOT NULL
),
/* -----------------------------------------------------------------
   4.  Classify sessions
------------------------------------------------------------------*/
classified AS (
    SELECT
        b.visitor_id,
        b.visit_id,
        TO_CHAR(b.session_date,'YYYY-MM')  AS month,
        CASE
            WHEN b.transactions >= 1 AND prs.visit_id IS NOT NULL
                 THEN 'Purchase'
            WHEN b.transactions IS NULL AND prs.visit_id IS NULL
                 THEN 'Non-Purchase'
        END                                AS session_type,
        COALESCE(b.pageviews,0)            AS pageviews
    FROM   base b
    LEFT   JOIN prod_rev_sessions prs
           ON  b.visitor_id = prs.visitor_id
           AND b.visit_id   = prs.visit_id
    WHERE  (b.transactions >= 1 AND prs.visit_id IS NOT NULL)
        OR (b.transactions IS NULL AND prs.visit_id IS NULL)
),
/* -----------------------------------------------------------------
   5.  Aggregate to visitor level (per month & type)
------------------------------------------------------------------*/
visitor_level AS (
    SELECT
        month,
        session_type,
        visitor_id,
        SUM(pageviews) AS visitor_pageviews
    FROM   classified
    GROUP  BY month, session_type, visitor_id
)
/* -----------------------------------------------------------------
   6.  Final result
------------------------------------------------------------------*/
SELECT
    month,
    session_type,
    AVG(visitor_pageviews) AS avg_pageviews_per_visitor
FROM   visitor_level
GROUP  BY month, session_type
ORDER  BY month, session_type;