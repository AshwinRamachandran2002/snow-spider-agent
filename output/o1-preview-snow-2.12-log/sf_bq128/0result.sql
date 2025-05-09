WITH patents_of_interest AS (
    SELECT DISTINCT p."id", p."title", p."abstract", p."date"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT AS p
    JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT AS c
        ON p."id" = c."patent_id"
    WHERE p."country" = 'US'
      AND p."date" BETWEEN '2014-01-01' AND '2014-01-31'
      AND (
            c."subsection_id" IN ('C5', 'C6', 'C7', 'C8', 'C9', 'C10', 'C11', 'C12', 'C13')
            OR c."group_id" IN ('A01G', 'A01H', 'A61K', 'A61P', 'A61Q', 'B01F', 'B01J', 'B81B', 'B82B', 'B82Y', 'G01N', 'G16H')
          )
),
backward_citations AS (
    SELECT p."id", COUNT(u."citation_id") AS "backward_count"
    FROM patents_of_interest p
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
        ON p."id" = u."patent_id"
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.PATENT p_cited
        ON u."citation_id" = p_cited."id"
    WHERE p_cited."date" BETWEEN DATEADD(year, -5, p."date") AND p."date"
    GROUP BY p."id"
),
forward_citations AS (
    SELECT p."id", COUNT(u."patent_id") AS "forward_count"
    FROM patents_of_interest p
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
        ON u."citation_id" = p."id"
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.PATENT p_citing
        ON u."patent_id" = p_citing."id"
    WHERE p_citing."date" BETWEEN p."date" AND DATEADD(year, 5, p."date")
    GROUP BY p."id"
)
SELECT
    p."title" AS "Title",
    p."abstract" AS "Abstract",
    p."date" AS "Publication_Date",
    COALESCE(bc."backward_count", 0) AS "Backward_Citation_Count",
    COALESCE(fc."forward_count", 0) AS "Forward_Citation_Count"
FROM patents_of_interest p
LEFT JOIN backward_citations bc ON p."id" = bc."id"
LEFT JOIN forward_citations fc ON p."id" = fc."id";