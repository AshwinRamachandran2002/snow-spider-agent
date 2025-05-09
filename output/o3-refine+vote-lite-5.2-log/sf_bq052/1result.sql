/*  Patents in CPC subsection C05 or CPC group A01G
    with backward / forward citations that fall within
    ±30 days of the patent’s application date              */

WITH
/* ------------------------------------------------------- */
/* 1. Patents that match the CPC filter                    */
cpc_patents AS (
    SELECT DISTINCT "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE  "subsection_id" = 'C05'
       OR  "group_id"      = 'A01G'
),

/* ------------------------------------------------------- */
/* 2. Clean application‑date table using TRY_TO_DATE        */
app_dates AS (
    SELECT  "patent_id",
            MIN( TRY_TO_DATE("date") )  AS "app_date"
    FROM    PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE   TRY_TO_DATE("date") IS NOT NULL        -- skip bad dates such as ‘YYYY‑MM‑00’
    GROUP BY "patent_id"
),

/* ------------------------------------------------------- */
/* 3. Core information for the filtered patents            */
patent_info AS (
    SELECT  p."id"            AS "patent_id",
            p."title",
            ad."app_date",
            p."abstract"
    FROM    cpc_patents                          cp
    JOIN    app_dates                            ad  ON ad."patent_id" = cp."patent_id"
    JOIN    PATENTSVIEW.PATENTSVIEW.PATENT       p   ON p."id"          = cp."patent_id"
),

/* ------------------------------------------------------- */
/* 4. Backward citations (≤30 days BEFORE application)     */
backward_cnt AS (
    SELECT  c."patent_id"                                      AS "patent_id",
            COUNT(DISTINCT c."citation_id")                    AS "back_before"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION           c
    JOIN    app_dates                 ad_f ON ad_f."patent_id" = c."patent_id"
    JOIN    app_dates                 ad_c ON ad_c."patent_id" = c."citation_id"
    WHERE   c."patent_id" IN ( SELECT "patent_id" FROM patent_info )
      AND   ad_c."app_date" IS NOT NULL
      AND   ad_f."app_date" IS NOT NULL
      AND   DATEDIFF('day', ad_c."app_date", ad_f."app_date") BETWEEN 0 AND 30
    GROUP BY c."patent_id"
),

/* ------------------------------------------------------- */
/* 5. Forward citations (≤30 days AFTER application)       */
forward_cnt AS (
    SELECT  c."citation_id"                                   AS "patent_id",
            COUNT(DISTINCT c."patent_id")                     AS "forw_after"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION          c
    JOIN    app_dates                 ad_f ON ad_f."patent_id" = c."citation_id"
    JOIN    app_dates                 ad_g ON ad_g."patent_id" = c."patent_id"
    WHERE   c."citation_id" IN ( SELECT "patent_id" FROM patent_info )
      AND   ad_f."app_date" IS NOT NULL
      AND   ad_g."app_date" IS NOT NULL
      AND   DATEDIFF('day', ad_f."app_date", ad_g."app_date") BETWEEN 0 AND 30
    GROUP BY c."citation_id"
)

/* ------------------------------------------------------- */
/* 6. Final result                                         */
SELECT  pi."patent_id",
        pi."title",
        pi."app_date"                         AS "application_date",
        COALESCE(b."back_before", 0)          AS "backward_citations_1m_before",
        COALESCE(f."forw_after" , 0)          AS "forward_citations_1m_after",
        pi."abstract"
FROM    patent_info  pi
LEFT JOIN backward_cnt b ON b."patent_id" = pi."patent_id"
LEFT JOIN forward_cnt f  ON f."patent_id" = pi."patent_id"
WHERE   COALESCE(b."back_before",0) > 0
     OR COALESCE(f."forw_after",0)  > 0
ORDER BY pi."app_date" ASC,
         pi."patent_id" ASC;