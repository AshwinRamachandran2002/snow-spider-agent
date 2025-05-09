/*-----------------------------------------------------------
  Retrieve patents in CPC subsection C05 or group A01G
  and count backward / forward citations inside a ±30-day
  window around the application date.
-----------------------------------------------------------*/
WITH current_patents AS (          -- valid application dates only
    SELECT 
        "patent_id",
        TRY_TO_DATE("date") AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE TRY_TO_DATE("date") IS NOT NULL
),
cpc_patents AS (                   -- patents in required CPC scopes
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE "subsection_id" = 'C05'
       OR "group_id"      = 'A01G'
),
/* backward citations: current patent → earlier patents ≤ 30 days */
backward AS (
    SELECT 
        uc."patent_id"                       AS "patent_id",
        COUNT(DISTINCT uc."citation_id")     AS "backward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN current_patents  cur   ON cur."patent_id"   = uc."patent_id"
    JOIN current_patents  cited ON cited."patent_id" = uc."citation_id"
    WHERE DATEDIFF('day', cited."app_date", cur."app_date") BETWEEN 1 AND 30
    GROUP BY uc."patent_id"
),
/* forward citations: later patents → current patent ≤ 30 days */
forward AS (
    SELECT 
        uc."citation_id"                     AS "patent_id",
        COUNT(DISTINCT uc."patent_id")       AS "forward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN current_patents cur    ON cur."patent_id"    = uc."citation_id"
    JOIN current_patents citing ON citing."patent_id" = uc."patent_id"
    WHERE DATEDIFF('day', cur."app_date", citing."app_date") BETWEEN 1 AND 30
    GROUP BY uc."citation_id"
)
/*---------------------------  final output  ---------------------------*/
SELECT 
    p."id"                                   AS "patent_id",
    p."title",
    cur."app_date"                           AS "application_date",
    COALESCE(b."backward_cnt", 0)            AS "backward_citations",
    COALESCE(f."forward_cnt", 0)             AS "forward_citations",
    p."abstract"
FROM PATENTSVIEW.PATENTSVIEW."PATENT"        p
JOIN current_patents                         cur ON cur."patent_id" = p."id"
JOIN cpc_patents                             cp  ON cp."patent_id"  = p."id"
LEFT JOIN backward                           b   ON b."patent_id"   = p."id"
LEFT JOIN forward                            f   ON f."patent_id"   = p."id"
WHERE COALESCE(b."backward_cnt",0) > 0 
   OR COALESCE(f."forward_cnt",0)  > 0
ORDER BY cur."app_date";