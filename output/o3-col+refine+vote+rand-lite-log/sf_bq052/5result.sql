/*  Patents in CPC subsection ‘C05’ or group ‘A01G’, together with
    30-day backward / forward citation counts around their earliest
    valid application date (invalid dates such as ‘1981-11-00’ are
    ignored by TRY_TO_DATE).                                                  */

WITH
/* 1.  Patents that have at least one relevant CPC code                         */
cpc_patents AS (
    SELECT DISTINCT
           "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE  "subsection_id" = 'C05'
       OR  "group_id"      = 'A01G'
),

/* 2.  Clean application dates; keep only parsable dates                        */
app_clean AS (
    SELECT
        "patent_id",
        TRY_TO_DATE("date") AS "dt"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
),

/* 3.  Earliest valid application date per patent                               */
app_dates AS (
    SELECT
        "patent_id",
        MIN("dt") AS "app_date"
    FROM   app_clean
    WHERE  "dt" IS NOT NULL
    GROUP BY "patent_id"
),

/* 4.  Forward citations within 0-30 days AFTER the application date            */
fw AS (
    SELECT
        base."patent_id",
        COUNT(DISTINCT uc."patent_id") AS "fw_cnt"
    FROM            cpc_patents                base
    JOIN            app_dates                  ad_base   ON ad_base."patent_id" = base."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
                                               ON uc."citation_id"  = base."patent_id"
    JOIN            app_dates                  ad_citer  ON ad_citer."patent_id" = uc."patent_id"
    WHERE ad_citer."app_date" BETWEEN ad_base."app_date"
                                  AND     ad_base."app_date" + 30
    GROUP BY base."patent_id"
),

/* 5.  Backward citations within 1-30 days BEFORE the application date          */
bw AS (
    SELECT
        base."patent_id",
        COUNT(DISTINCT uc."patent_id") AS "bw_cnt"
    FROM            cpc_patents                base
    JOIN            app_dates                  ad_base   ON ad_base."patent_id" = base."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
                                               ON uc."citation_id"  = base."patent_id"
    JOIN            app_dates                  ad_citer  ON ad_citer."patent_id" = uc."patent_id"
    WHERE ad_citer."app_date" BETWEEN ad_base."app_date" - 30
                                  AND     ad_base."app_date" - 1
    GROUP BY base."patent_id"
),

/* 6.  Keep patents that have at least one citation in either window            */
counts AS (
    SELECT
        COALESCE(fw."patent_id", bw."patent_id") AS "patent_id",
        COALESCE(bw."bw_cnt", 0)                 AS "backward_30d",
        COALESCE(fw."fw_cnt", 0)                 AS "forward_30d"
    FROM fw
    FULL OUTER JOIN bw ON fw."patent_id" = bw."patent_id"
    WHERE COALESCE(bw."bw_cnt", 0) > 0
       OR COALESCE(fw."fw_cnt", 0) > 0
)

/* 7.  Final output with bibliographic details                                   */
SELECT
    c."patent_id",
    p."title",
    ad."app_date"                        AS "application_date",
    c."backward_30d",
    c."forward_30d",
    p."abstract"
FROM        counts                             c
JOIN        app_dates                          ad ON ad."patent_id" = c."patent_id"
JOIN PATENTSVIEW.PATENTSVIEW."PATENT"          p  ON p."id"         = c."patent_id"
ORDER BY ad."app_date" ASC NULLS LAST;