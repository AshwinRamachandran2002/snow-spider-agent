/*  Patents in CPC subsections G06 (Computing) or C12 (Biochemistry) that             */
/*  (1) cite at least one earlier U.S. patent within 1-yr BEFORE their application   */
/*      date (“backward” window)                                                    */
/*  (2) are cited by at least one later U.S. patent within 1-yr AFTER their          */
/*      application date (“forward-1-yr” window)                                    */
/*  and we report the count of forward citations that arrive within 3-yrs           */
/*  after the application date.                                                     */
/*  The single patent with the highest backward-citation count is returned.         */

WITH app AS (            /* parse application dates once */
    SELECT
        "patent_id",
        TRY_TO_DATE("date") AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE TRY_TO_DATE("date") IS NOT NULL
),

/* --------------------  BACKWARD citations (–1 yr)  -------------------- */
back_1yr AS (
    SELECT
        c."patent_id",
        COUNT(*) AS "back_cnt_1yr"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  c
    JOIN app a
      ON c."patent_id" = a."patent_id"
    WHERE TRY_TO_DATE(c."date") IS NOT NULL
      AND TRY_TO_DATE(c."date")
          BETWEEN DATEADD(year,-1,a."app_date") AND a."app_date"
    GROUP BY c."patent_id"
),

/* --------------------  FORWARD citations (+1 yr)  -------------------- */
fwd_1yr AS (
    SELECT
        c."citation_id" AS "patent_id",
        COUNT(*)        AS "fwd_cnt_1yr"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  c
    JOIN app a
      ON c."citation_id" = a."patent_id"
    WHERE TRY_TO_DATE(c."date") IS NOT NULL
      AND TRY_TO_DATE(c."date")
          BETWEEN a."app_date" AND DATEADD(year,1,a."app_date")
    GROUP BY c."citation_id"
),

/* --------------------  FORWARD citations (+3 yrs)  -------------------- */
fwd_3yr AS (
    SELECT
        c."citation_id" AS "patent_id",
        COUNT(*)        AS "fwd_cnt_3yr"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  c
    JOIN app a
      ON c."citation_id" = a."patent_id"
    WHERE TRY_TO_DATE(c."date") IS NOT NULL
      AND TRY_TO_DATE(c."date")
          BETWEEN a."app_date" AND DATEADD(year,3,a."app_date")
    GROUP BY c."citation_id"
),

/* --------------------  Patents meeting BOTH 1-yr windows  -------------------- */
both_windows AS (
    SELECT
        b."patent_id",
        b."back_cnt_1yr",
        f1."fwd_cnt_1yr",
        f3."fwd_cnt_3yr"
    FROM back_1yr b
    JOIN fwd_1yr f1 ON b."patent_id" = f1."patent_id"
    JOIN fwd_3yr f3 ON b."patent_id" = f3."patent_id"
),

/* --------------------  Limit to chosen CPC subsections  -------------------- */
tech_filtered AS (
    SELECT DISTINCT
        bw."patent_id",
        bw."back_cnt_1yr",
        bw."fwd_cnt_1yr",
        bw."fwd_cnt_3yr"
    FROM both_windows                         bw
    JOIN PATENTSVIEW.PATENTSVIEW."CPC_CURRENT" cp
      ON bw."patent_id" = cp."patent_id"
    WHERE cp."subsection_id" IN ('G06','C12')     -- specific CPC categories
)

/* --------------------  Final result: most backward-cited patent  -------------------- */
SELECT
    tf."patent_id",
    tf."back_cnt_1yr"  AS "backward_citations_1yr",
    tf."fwd_cnt_1yr"   AS "forward_citations_1yr",
    tf."fwd_cnt_3yr"   AS "forward_citations_3yr"
FROM tech_filtered tf
ORDER BY tf."back_cnt_1yr" DESC NULLS LAST
LIMIT 1;