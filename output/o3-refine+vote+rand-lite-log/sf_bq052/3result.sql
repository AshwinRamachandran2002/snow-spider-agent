WITH
/* ---------- 1.  Application dates converted safely to DATE ---------- */
app_dates AS (
    SELECT
        "patent_id",
        TRY_TO_DATE("date",'YYYY-MM-DD') AS "app_date"      -- invalid strings → NULL
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE "date" IS NOT NULL
),
/* ---------- 2.  Patents in the requested CPC classes that have a valid date ---------- */
target_patents AS (
    SELECT
        p."id"                  AS "patent_id",
        p."title"               AS "title",
        ad."app_date"           AS "application_date",
        p."abstract"            AS "abstract"
    FROM PATENTSVIEW.PATENTSVIEW."PATENT"      p
    JOIN app_dates                               ad   ON ad."patent_id" = p."id"
    JOIN PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"   cpc  ON cpc."patent_id" = p."id"
    WHERE ad."app_date" IS NOT NULL
      AND ( cpc."subsection_id" = 'C05'          -- subsection filter
            OR cpc."group_id"   = 'A01G')        -- group filter
),
/* ---------- 3.  Backward citations within 1‑month window ---------- */
backward AS (
    SELECT
        tp."patent_id",
        COUNT(DISTINCT uc."citation_id") AS "backward_cnt"
    FROM target_patents tp
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
         ON uc."patent_id" = tp."patent_id"                 -- focal → older
    JOIN app_dates cited   ON cited."patent_id" = uc."citation_id"
    WHERE cited."app_date" IS NOT NULL
      AND cited."app_date" >= DATEADD('month',-1, tp."application_date")
      AND cited."app_date" <  tp."application_date"
    GROUP BY tp."patent_id"
),
/* ---------- 4.  Forward citations within 1‑month window ---------- */
forward AS (
    SELECT
        tp."patent_id",
        COUNT(DISTINCT uc."patent_id") AS "forward_cnt"
    FROM target_patents tp
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
         ON uc."citation_id" = tp."patent_id"               -- newer → focal
    JOIN app_dates citing  ON citing."patent_id" = uc."patent_id"
    WHERE citing."app_date" IS NOT NULL
      AND citing."app_date" >  tp."application_date"
      AND citing."app_date" <= DATEADD('month',1, tp."application_date")
    GROUP BY tp."patent_id"
)
/* ---------- 5.  Final result ---------- */
SELECT
    tp."patent_id",
    tp."title",
    tp."application_date",
    COALESCE(b."backward_cnt", 0) AS "backward_citations_1m",
    COALESCE(f."forward_cnt", 0)  AS "forward_citations_1m",
    tp."abstract"
FROM target_patents tp
LEFT JOIN backward b ON b."patent_id" = tp."patent_id"
LEFT JOIN forward  f ON f."patent_id" = tp."patent_id"
WHERE COALESCE(b."backward_cnt",0) > 0
   OR COALESCE(f."forward_cnt",0) > 0
ORDER BY tp."application_date" ASC,
         tp."patent_id";