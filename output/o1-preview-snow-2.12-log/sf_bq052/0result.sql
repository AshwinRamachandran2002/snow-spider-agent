WITH candidate_patents AS (
    SELECT DISTINCT p."id", p."title"
    FROM "PATENTSVIEW"."PATENTSVIEW"."PATENT" p
    JOIN "PATENTSVIEW"."PATENTSVIEW"."CPC_CURRENT" cpc ON p."id" = cpc."patent_id"
    WHERE p."country" = 'US' AND (cpc."subsection_id" = 'C05' OR cpc."group_id" = 'A01G')
),
application_dates AS (
    SELECT "patent_id", "date" AS "application_date"
    FROM "PATENTSVIEW"."PATENTSVIEW"."APPLICATION"
    WHERE TRY_TO_DATE("date", 'YYYY-MM-DD') IS NOT NULL
),
candidate_with_dates AS (
    SELECT cp.*, ad."application_date"
    FROM candidate_patents cp
    JOIN application_dates ad ON cp."id" = ad."patent_id"
),
forward_citations AS (
    SELECT c."citation_id" AS "patent_id", COUNT(*) AS "forward_citation_count"
    FROM "PATENTSVIEW"."PATENTSVIEW"."USPATENTCITATION" c
    JOIN application_dates a_our ON c."citation_id" = a_our."patent_id"
    JOIN application_dates a_citing ON c."patent_id" = a_citing."patent_id"
    WHERE ABS(DATEDIFF('day', TRY_TO_DATE(a_citing."application_date", 'YYYY-MM-DD'), TRY_TO_DATE(a_our."application_date", 'YYYY-MM-DD'))) <= 30
    GROUP BY c."citation_id"
),
backward_citations AS (
    SELECT c."patent_id", COUNT(*) AS "backward_citation_count"
    FROM "PATENTSVIEW"."PATENTSVIEW"."USPATENTCITATION" c
    JOIN application_dates a_our ON c."patent_id" = a_our."patent_id"
    JOIN application_dates a_cited ON c."citation_id" = a_cited."patent_id"
    WHERE ABS(DATEDIFF('day', TRY_TO_DATE(a_cited."application_date", 'YYYY-MM-DD'), TRY_TO_DATE(a_our."application_date", 'YYYY-MM-DD'))) <= 30
    GROUP BY c."patent_id"
)
SELECT 
    CAST(cpw."id" AS STRING) AS "id",
    CAST(cpw."title" AS STRING) AS "title",
    CAST(cpw."application_date" AS STRING) AS "application_date",
    COALESCE(fc."forward_citation_count", 0) AS "forward_citation_count",
    COALESCE(bc."backward_citation_count", 0) AS "backward_citation_count",
    CAST(b."text" AS STRING) AS "summary_text"
FROM candidate_with_dates cpw
LEFT JOIN forward_citations fc ON cpw."id" = fc."patent_id"
LEFT JOIN backward_citations bc ON cpw."id" = bc."patent_id"
LEFT JOIN "PATENTSVIEW"."PATENTSVIEW"."BRF_SUM_TEXT" b ON cpw."id" = b."patent_id"
WHERE (COALESCE(fc."forward_citation_count",0) >=1 OR COALESCE(bc."backward_citation_count",0) >=1)
LIMIT 100;