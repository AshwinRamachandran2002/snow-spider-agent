WITH raw_app AS (                    -- convert dates, ignore invalid values
    SELECT
        "patent_id",
        TRY_TO_DATE("date",'YYYY-MM-DD') AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE "country" = 'US'
), 
cte_app AS (                         -- earliest valid U.S. application date
    SELECT
        "patent_id",
        MIN("app_date") AS "app_date"
    FROM raw_app
    WHERE "app_date" IS NOT NULL
    GROUP BY "patent_id"
), 
cte_focus AS (                       -- patents in requested CPC classes
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "section_id" = 'C' AND "subsection_id" = 'C05'
    
    UNION ALL
    
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "group_id" = 'A01G'
), 
cte_back AS (                        -- backward citations ≤1 month BEFORE app date
    SELECT
        uc."patent_id"                       AS "focal_id",
        COUNT(DISTINCT uc."citation_id")     AS "back_cnt"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN cte_app a_focal  ON a_focal."patent_id" = uc."patent_id"
    JOIN cte_app a_cited  ON a_cited."patent_id" = uc."citation_id"
    WHERE a_cited."app_date" >= DATEADD(month,-1, a_focal."app_date")
      AND a_cited."app_date" <  a_focal."app_date"
    GROUP BY uc."patent_id"
), 
cte_forw AS (                        -- forward citations <1 month AFTER app date
    SELECT
        uc."citation_id"                    AS "focal_id",
        COUNT(DISTINCT uc."patent_id")      AS "fwd_cnt"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN cte_app a_focal  ON a_focal."patent_id" = uc."citation_id"
    JOIN cte_app a_citing ON a_citing."patent_id" = uc."patent_id"
    WHERE a_citing."app_date" >= a_focal."app_date"
      AND a_citing."app_date" <  DATEADD(month,1, a_focal."app_date")
    GROUP BY uc."citation_id"
)
SELECT
    p."id"                              AS "patent_id",
    p."title",
    a."app_date"                        AS "application_date",
    COALESCE(b."back_cnt",0)            AS "backward_citations_1m_before",
    COALESCE(f."fwd_cnt",0)             AS "forward_citations_1m_after",
    p."abstract"
FROM cte_focus                    fcs
JOIN PATENTSVIEW.PATENTSVIEW.PATENT  p  ON p."id" = fcs."patent_id"
JOIN cte_app                          a  ON a."patent_id" = p."id"
LEFT JOIN cte_back                    b  ON b."focal_id"  = p."id"
LEFT JOIN cte_forw                    f  ON f."focal_id"  = p."id"
WHERE COALESCE(b."back_cnt",0) > 0 
   OR COALESCE(f."fwd_cnt",0)  > 0
ORDER BY a."app_date" ASC, p."id";