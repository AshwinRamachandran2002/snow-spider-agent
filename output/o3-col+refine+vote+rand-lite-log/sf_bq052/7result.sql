/*  Patents in CPC subsection C05 (fertilisers) or group A01G (horticulture)
    – number of citations 30 days before (backward) and after (forward)
      the application date                                             */

WITH apps AS (   -- application dates (converted to DATE)
    SELECT
        "patent_id",
        TRY_TO_DATE("date") AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE "date" IS NOT NULL
),
cpc_filter AS (  -- keep only the requested CPC categories
    SELECT DISTINCT
        "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE "subsection_id" = 'C05'
       OR "group_id"      = 'A01G'
),
backward AS (    -- citations MADE BY the patent ≤30 days BEFORE its app. date
    SELECT
        ap."patent_id",
        COUNT(*) AS "backward_cnt"
    FROM apps ap
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
          ON uc."patent_id" = ap."patent_id"          -- citing = current patent
    WHERE TRY_TO_DATE(uc."date")
          BETWEEN DATEADD(DAY, -30, ap."app_date")
              AND DATEADD(DAY,  -1, ap."app_date")
    GROUP BY ap."patent_id"
),
forward AS (     -- citations RECEIVED BY the patent ≤30 days AFTER its app. date
    SELECT
        ap."patent_id",
        COUNT(*) AS "forward_cnt"
    FROM apps ap
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
          ON uc."citation_id" = ap."patent_id"        -- cited = current patent
    WHERE TRY_TO_DATE(uc."date")
          BETWEEN ap."app_date"
              AND DATEADD(DAY, 30, ap."app_date")
    GROUP BY ap."patent_id"
)

SELECT
    p."id"                               AS "patent_id",
    p."title",
    TO_CHAR(ap."app_date", 'YYYY-MM-DD') AS "application_date",
    COALESCE(b."backward_cnt", 0)        AS "backward_citations_1m_before",
    COALESCE(f."forward_cnt", 0)         AS "forward_citations_1m_after",
    p."abstract"
FROM PATENTSVIEW.PATENTSVIEW."PATENT" p
JOIN apps        ap ON ap."patent_id" = p."id"
JOIN cpc_filter  cf ON cf."patent_id" = p."id"
LEFT JOIN backward b ON b."patent_id" = p."id"
LEFT JOIN forward  f ON f."patent_id" = p."id"
WHERE COALESCE(b."backward_cnt", 0) > 0
   OR COALESCE(f."forward_cnt", 0) > 0
ORDER BY ap."app_date";