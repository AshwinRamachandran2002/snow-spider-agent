/*  -------------------------------------------------------------
    U.S. patents in CPC sections G or H that
      • have ≥1 backward citation filed within 1 year BEFORE their
        own application date
      • have ≥1 forward citation filed within 1 year AFTER
      • return the count of forward citations within 3 years AFTER
    and keep only the patent with the greatest number of such
    backward citations.
    ------------------------------------------------------------- */
WITH app AS (
    SELECT  "patent_id",
            MIN(TRY_TO_DATE("date")) AS "app_date"
    FROM    PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE   TRY_TO_DATE("date") IS NOT NULL
    GROUP BY "patent_id"
),
/* ───────────────────────────────────────────────────────────── */
back_1y AS (
    SELECT  u."patent_id",
            COUNT(*) AS "backward_1y"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
    JOIN    app AS cur    ON cur."patent_id"   = u."patent_id"
    JOIN    app AS cited  ON cited."patent_id" = u."citation_id"
    WHERE   cited."app_date" BETWEEN DATEADD(year,-1,cur."app_date")
                                AND                     cur."app_date"
    GROUP BY u."patent_id"
),
/* ───────────────────────────────────────────────────────────── */
fwd_1y AS (
    SELECT  u."citation_id" AS "patent_id",
            COUNT(*)        AS "forward_1y"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
    JOIN    app AS cur     ON cur."patent_id"   = u."citation_id"
    JOIN    app AS citing  ON citing."patent_id" = u."patent_id"
    WHERE   citing."app_date" BETWEEN cur."app_date"
                                 AND DATEADD(year,1,cur."app_date")
    GROUP BY u."citation_id"
),
/* ───────────────────────────────────────────────────────────── */
fwd_3y AS (
    SELECT  u."citation_id" AS "patent_id",
            COUNT(*)        AS "forward_3y"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
    JOIN    app AS cur     ON cur."patent_id"   = u."citation_id"
    JOIN    app AS citing  ON citing."patent_id" = u."patent_id"
    WHERE   citing."app_date" BETWEEN cur."app_date"
                                 AND DATEADD(year,3,cur."app_date")
    GROUP BY u."citation_id"
),
/* ─────────────────────────────────────────────────────────────
   Restrict to desired CPC technology areas (here: sections G,H)
   ───────────────────────────────────────────────────────────── */
cpc_keep AS (
    SELECT DISTINCT "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE  "section_id" IN ('G','H')          -- adjust as needed
),
/*  Collect CPC section list for display */
cpc_info AS (
    SELECT  "patent_id",
            LISTAGG(DISTINCT "section_id", ',')
            WITHIN GROUP (ORDER BY "section_id") AS "cpc_category"
    FROM    PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    GROUP BY "patent_id"
)
/* ───────────────────────────────────────────────────────────── */
SELECT
    p."number"                                          AS patent_number,
    TO_CHAR(a."app_date", 'YYYY-MM-DD')                 AS application_date,
    ci."cpc_category"                                   AS cpc_category,
    b."backward_1y"                                     AS backward_citations_within_1yr,
    f1."forward_1y"                                     AS forward_citations_within_1yr,
    f3."forward_3y"                                     AS forward_citations_within_3yrs
FROM   back_1y             b
JOIN   fwd_1y              f1  ON f1."patent_id" = b."patent_id"
JOIN   fwd_3y              f3  ON f3."patent_id" = b."patent_id"
JOIN   cpc_keep            ck  ON ck."patent_id" = b."patent_id"
JOIN   PATENTSVIEW.PATENTSVIEW.PATENT  p  ON p."id" = b."patent_id"
                                        AND p."country" = 'US'
JOIN   app                 a   ON a."patent_id" = b."patent_id"
LEFT  JOIN cpc_info         ci  ON ci."patent_id" = b."patent_id"
ORDER BY b."backward_1y" DESC NULLS LAST, p."number"
LIMIT 1;