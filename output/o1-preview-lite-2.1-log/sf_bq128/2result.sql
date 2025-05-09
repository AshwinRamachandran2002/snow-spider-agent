WITH qualified_patents AS (
    SELECT DISTINCT p."id", p."title", p."abstract", p."date" AS "publication_date"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT p
    INNER JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT c ON p."id" = c."patent_id"
    WHERE p."date" BETWEEN '2014-01-01' AND '2014-01-31'
      AND p."country" = 'US'
      AND (
           (c."subsection_id" BETWEEN 'C05' AND 'C13')
           OR c."group_id" IN ('A01G', 'A01H', 'A61K', 'A61P', 'A61Q',
                               'B01F', 'B01J', 'B81B', 'B82B', 'B82Y',
                               'G01N', 'G16H')
          )
)
SELECT qp."title", qp."abstract", qp."publication_date",
       COALESCE((
           SELECT COUNT(DISTINCT b."citation_id")
           FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION b
           JOIN PATENTSVIEW.PATENTSVIEW.PATENT bp ON b."citation_id" = bp."id"
           WHERE b."patent_id" = qp."id"
             AND bp."date" BETWEEN DATEADD(year, -5, qp."publication_date") AND qp."publication_date"
       ), 0) AS "backward_citation_count",
       COALESCE((
           SELECT COUNT(DISTINCT f."patent_id")
           FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION f
           JOIN PATENTSVIEW.PATENTSVIEW.PATENT fp ON f."patent_id" = fp."id"
           WHERE f."citation_id" = qp."id"
             AND fp."date" BETWEEN qp."publication_date" AND DATEADD(year, 5, qp."publication_date")
       ), 0) AS "forward_citation_count"
FROM qualified_patents qp;