/*---------------------------------------------------------------
   1)  Earliest valid application date for every patent
   2)  Patents that lie in CPC‑subsection  C05   OR   CPC‑group  A01G
   3)  “Backward”   citations  – patents that the focal patent cites
   4)  “Forward”    citations  – patents that cite the focal patent
   5)  Count citations falling in the required ±1‑month windows
   6)  Keep patents that have ≥1 backward OR forward citation
----------------------------------------------------------------*/
WITH application_dates AS (          /* 1 */
    SELECT
        "patent_id",
        MIN(TRY_TO_DATE("date",'YYYY-MM-DD')) AS "application_date"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    GROUP BY "patent_id"
    HAVING "application_date" IS NOT NULL
),  
cpc_filtered_patents AS (            /* 2 */
    SELECT DISTINCT
        "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "subsection_id" = 'C05'
       OR "group_id"      = 'A01G'
),
/* ---------- Backward citations (focal patent  ➜  earlier patents) ----------- */
backward_cte AS (                    /* 3 */
    SELECT
        uc."patent_id"                                  AS "patent_id",
        COUNT(*)                                        AS "backward_citations_1m"
    FROM application_dates   ad
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc 
         ON uc."patent_id" = ad."patent_id"
    WHERE TRY_TO_DATE(uc."date",'YYYY-MM-DD') 
              BETWEEN DATEADD(month,-1, ad."application_date") 
                  AND DATEADD(day,-1 , ad."application_date")     /* < application date */
    GROUP BY uc."patent_id"
),
/* ---------- Forward citations (later patents ➜ focal patent) --------------- */
forward_cte AS (                     /* 4 */
    SELECT
        uc."citation_id"                                AS "patent_id",
        COUNT(*)                                        AS "forward_citations_1m"
    FROM application_dates   ad
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
         ON uc."citation_id" = ad."patent_id"
    WHERE TRY_TO_DATE(uc."date",'YYYY-MM-DD') 
              BETWEEN ad."application_date" 
                  AND DATEADD(month, 1, ad."application_date")    /* < +1 month */
    GROUP BY uc."citation_id"
),
/* ---------- Combine citation counts ---------------------------------------- */
citation_counts AS (                 /* 5 */
    SELECT
        ad."patent_id",
        COALESCE(bw."backward_citations_1m", 0) AS "backward_citations_1m",
        COALESCE(fw."forward_citations_1m",  0) AS "forward_citations_1m"
    FROM application_dates ad
    LEFT JOIN backward_cte bw ON ad."patent_id" = bw."patent_id"
    LEFT JOIN forward_cte  fw ON ad."patent_id" = fw."patent_id"
),
/* ---------- Core bibliographic information --------------------------------- */
patent_info AS (
    SELECT
        "id"        AS "patent_id",
        "title",
        "abstract"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT
)
/* ------------------------------ FINAL RESULT -------------------------------- */
SELECT
    ad."patent_id",
    pi."title",
    ad."application_date",
    cc."backward_citations_1m",
    cc."forward_citations_1m",
    pi."abstract"      AS "abstract_text"
FROM application_dates      ad
JOIN cpc_filtered_patents   cf ON ad."patent_id" = cf."patent_id"
JOIN citation_counts        cc ON ad."patent_id" = cc."patent_id"
JOIN patent_info            pi ON ad."patent_id" = pi."patent_id"
WHERE cc."backward_citations_1m" > 0
   OR cc."forward_citations_1m"  > 0
ORDER BY ad."application_date" ASC,
         ad."patent_id"        ASC;