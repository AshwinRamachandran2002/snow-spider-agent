WITH
patents_of_interest AS (
    SELECT DISTINCT p."id", p."title", p."abstract", p."date"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT p
    JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT c
        ON p."id" = c."patent_id"
    WHERE p."date" BETWEEN '2014-01-01' AND '2014-01-31'
        AND p."country" = 'US'
        AND (
            c."subsection_id" IN ('C05', 'C06', 'C07', 'C08', 'C09', 'C10', 'C11', 'C12', 'C13')
            OR c."group_id" IN ('A01G', 'A01H', 'A61K', 'A61P', 'A61Q', 'B01F', 'B01J', 'B81B', 'B82B', 'B82Y', 'G01N', 'G16H')
        )
),
backward_citations AS (
    SELECT
        p."id" AS "patent_id",
        COUNT(DISTINCT c1."citation_id") AS "Backward_Citation_Count"
    FROM patents_of_interest p
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c1
        ON p."id" = c1."patent_id"
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.PATENT p_cited
        ON c1."citation_id" = p_cited."id"
    WHERE p_cited."date" BETWEEN DATEADD('year', -5, p."date") AND p."date"
    GROUP BY p."id"
),
forward_citations AS (
    SELECT
        p."id" AS "patent_id",
        COUNT(DISTINCT c2."patent_id") AS "Forward_Citation_Count"
    FROM patents_of_interest p
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c2
        ON p."id" = c2."citation_id"
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.PATENT p_citing
        ON c2."patent_id" = p_citing."id"
    WHERE p_citing."date" BETWEEN p."date" AND DATEADD('year', 5, p."date")
    GROUP BY p."id"
)
SELECT
    p."title" AS "Title",
    p."abstract" AS "Abstract",
    p."date" AS "Publication_Date",
    COALESCE(bc."Backward_Citation_Count", 0) AS "Backward_Citation_Count",
    COALESCE(fc."Forward_Citation_Count", 0) AS "Forward_Citation_Count"
FROM patents_of_interest p
LEFT JOIN backward_citations bc
    ON p."id" = bc."patent_id"
LEFT JOIN forward_citations fc
    ON p."id" = fc."patent_id";