WITH app_date AS (   -- 1) earliest valid U.S. application date for every patent
    SELECT
        "patent_id",
        MIN(TRY_TO_DATE("date")) AS "application_date"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE TRY_TO_DATE("date") IS NOT NULL
    GROUP BY "patent_id"
),

filtered_patents AS (   -- 2) patents that are in CPC subsection C05 or group A01G
    SELECT
        p."id"   AS "patent_id",
        p."title",
        ad."application_date",
        p."abstract"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT           p
    JOIN app_date                                  ad ON ad."patent_id" = p."id"
    JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT       c  ON c."patent_id"  = p."id"
    WHERE c."subsection_id" = 'C05'
       OR c."group_id"      = 'A01G'
    GROUP BY
        p."id",
        p."title",
        ad."application_date",
        p."abstract"
),

backward AS (   -- 3) citations MADE BY the patent within 1‑month window before its application date
    SELECT
        fp."patent_id",
        COUNT(*) AS "backward_cnt"
    FROM filtered_patents                             fp
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION     uc
         ON  uc."patent_id" = fp."patent_id"
    WHERE TRY_TO_DATE(uc."date") IS NOT NULL
      AND TRY_TO_DATE(uc."date") >= DATEADD(month,-1, fp."application_date")
      AND TRY_TO_DATE(uc."date") <  fp."application_date"
    GROUP BY fp."patent_id"
),

forward AS (   -- 4) citations RECEIVED BY the patent within 1‑month window after its application date
    SELECT
        fp."patent_id",
        COUNT(*) AS "forward_cnt"
    FROM filtered_patents                             fp
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION     uc
         ON  uc."citation_id" = fp."patent_id"
    WHERE TRY_TO_DATE(uc."date") IS NOT NULL
      AND TRY_TO_DATE(uc."date")  >  fp."application_date"
      AND TRY_TO_DATE(uc."date") <= DATEADD(month, 1, fp."application_date")
    GROUP BY fp."patent_id"
)

SELECT
    fp."patent_id",
    fp."title",
    fp."application_date",
    COALESCE(b."backward_cnt", 0) AS "backward_citations_within_1m_before",
    COALESCE(f."forward_cnt", 0)  AS "forward_citations_within_1m_after",
    fp."abstract"
FROM filtered_patents fp
LEFT JOIN backward b ON b."patent_id" = fp."patent_id"
LEFT JOIN forward  f ON f."patent_id" = fp."patent_id"
WHERE COALESCE(b."backward_cnt",0) > 0
   OR COALESCE(f."forward_cnt",0) > 0
ORDER BY fp."application_date", fp."patent_id";