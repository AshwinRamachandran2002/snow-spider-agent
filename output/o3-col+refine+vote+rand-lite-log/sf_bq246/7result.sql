WITH app AS (   -- application year for every patent
    SELECT 
        "patent_id",
        TO_NUMBER(SUBSTR("date",1,4)) AS "app_year"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
),

/* backward citations ≤ 1 year before the current patent’s application year */
bwd AS (
    SELECT 
        c."patent_id",
        COUNT(*) AS "bwd1yr"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" c
    JOIN app acurr ON acurr."patent_id" = c."patent_id"
    JOIN app aold  ON aold."patent_id"  = c."citation_id"
    WHERE acurr."app_year" - aold."app_year" BETWEEN 0 AND 1
    GROUP BY c."patent_id"
),

/* forward citations ≤ 3 years after the current patent’s application year */
fwd3 AS (
    SELECT 
        c."citation_id" AS "patent_id",
        COUNT(*)        AS "fwd3yr"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" c
    JOIN app aorig  ON aorig."patent_id"  = c."citation_id"
    JOIN app acite  ON acite."patent_id"  = c."patent_id"
    WHERE acite."app_year" - aorig."app_year" BETWEEN 0 AND 3
    GROUP BY c."citation_id"
),

/* forward citations ≤ 1 year (used only for filtering) */
fwd1 AS (
    SELECT 
        c."citation_id" AS "patent_id",
        COUNT(*)        AS "fwd1yr"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" c
    JOIN app aorig  ON aorig."patent_id"  = c."citation_id"
    JOIN app acite  ON acite."patent_id"  = c."patent_id"
    WHERE acite."app_year" - aorig."app_year" BETWEEN 0 AND 1
    GROUP BY c."citation_id"
),

/* patents belonging to the target CPC groups */
cpc AS (
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE "group_id" IN ('H04L','H04W','H04N')
)

SELECT 
    b."patent_id",
    b."bwd1yr",
    f3."fwd3yr"
FROM bwd  b
JOIN fwd1 f1 ON f1."patent_id" = b."patent_id"           -- must have ≥1 fwd citation within 1 yr
JOIN fwd3 f3 ON f3."patent_id" = b."patent_id"
JOIN cpc  c  ON c."patent_id"  = b."patent_id"
ORDER BY b."bwd1yr" DESC NULLS LAST
LIMIT 1;