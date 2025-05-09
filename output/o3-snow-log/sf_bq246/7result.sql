WITH app AS (   -- application dates parsed safely
    SELECT 
        "patent_id",
        TRY_TO_DATE("date") AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE TRY_TO_DATE("date") IS NOT NULL
),

/* ----------  backward citations: ≤ 1 year before application ---------- */
back_1yr AS (
    SELECT 
        uc."patent_id"                    AS "patent_id",
        COUNT(*)                          AS "back_1yr_ct"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN app a_citing  ON a_citing."patent_id"  = uc."patent_id"
    JOIN app a_cited   ON a_cited."patent_id"   = uc."citation_id"
    WHERE DATEDIFF('day', a_cited."app_date", a_citing."app_date") 
          BETWEEN 1 AND 365
    GROUP BY uc."patent_id"
),

/* ----------  forward citations: ≤ 3 years after application ---------- */
fwd_3yr AS (
    SELECT 
        uc."citation_id"                  AS "patent_id",
        COUNT(*)                          AS "fwd_3yr_ct"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN app a_target ON a_target."patent_id" = uc."citation_id"
    JOIN app a_citing ON a_citing."patent_id" = uc."patent_id"
    WHERE DATEDIFF('day', a_target."app_date", a_citing."app_date") 
          BETWEEN 0 AND 1095       -- 3 years
    GROUP BY uc."citation_id"
),

/* ----------  forward citations: ≤ 1 year after application (filter) --- */
fwd_1yr AS (
    SELECT 
        uc."citation_id"                  AS "patent_id",
        COUNT(*)                          AS "fwd_1yr_ct"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN app a_target ON a_target."patent_id" = uc."citation_id"
    JOIN app a_citing ON a_citing."patent_id" = uc."patent_id"
    WHERE DATEDIFF('day', a_target."app_date", a_citing."app_date") 
          BETWEEN 0 AND 365        -- 1 year
    GROUP BY uc."citation_id"
),

/* ----------  patents meeting both backward-&-forward filters ---------- */
both_dirs AS (
    SELECT 
        b."patent_id",
        b."back_1yr_ct",
        f3."fwd_3yr_ct"
    FROM back_1yr b
    JOIN fwd_3yr f3 ON f3."patent_id" = b."patent_id"
    JOIN fwd_1yr f1 ON f1."patent_id" = b."patent_id"   -- ensures ≥1 forward-within-1 yr
)

/* ----------  final selection in chosen CPC subsections --------------- */
SELECT 
    cc."patent_id",
    bd."back_1yr_ct"   AS "backward_citations_within_1yr",
    bd."fwd_3yr_ct"    AS "forward_citations_within_3yr"
FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT cc
JOIN both_dirs bd ON bd."patent_id" = cc."patent_id"
WHERE cc."subsection_id" IN ('C08', 'G06')   --  specific CPC categories
ORDER BY bd."back_1yr_ct" DESC NULLS LAST
LIMIT 1;