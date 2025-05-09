WITH base_patents AS (
    SELECT DISTINCT
           p."id"                    AS patent_id,
           p."title",
           p."abstract",
           TO_DATE(p."date")         AS publication_date,
           TO_DATE(a."date")         AS filing_date
    FROM   PATENTSVIEW.PATENTSVIEW.PATENT        p
           JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION    a
                 ON p."id" = a."patent_id"
           JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT     c
                 ON p."id" = c."patent_id"
    WHERE  p."country"   = 'US'
      AND  a."country"   = 'US'
      AND  TO_DATE(a."date") BETWEEN '2014-01-01' AND '2014-02-01'
      AND  (
              c."subsection_id" IN ('C05','C06','C07','C08','C09','C10',
                                    'C11','C12','C13')
           OR c."group_id"     IN ('A01G','A01H','A61K','A61P','A61Q',
                                    'B01F','B01J','B81B','B82B','B82Y',
                                    'G01N','G16H')
          )
),
backward_cites AS (
    SELECT bp.patent_id,
           COUNT(DISTINCT uc."citation_id") AS backward_count
    FROM   base_patents bp
           LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
                  ON uc."patent_id" = bp.patent_id
           LEFT JOIN PATENTSVIEW.PATENTSVIEW.PATENT cited
                  ON cited."id" = uc."citation_id"
    WHERE  cited."date" IS NOT NULL
      AND  TO_DATE(cited."date") < bp.filing_date
    GROUP BY bp.patent_id
),
forward_cites AS (
    SELECT bp.patent_id,
           COUNT(DISTINCT uc."patent_id") AS forward_count
    FROM   base_patents bp
           LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
                  ON uc."citation_id" = bp.patent_id
           LEFT JOIN PATENTSVIEW.PATENTSVIEW.PATENT citing
                  ON citing."id" = uc."patent_id"
    WHERE  citing."date" IS NOT NULL
      AND  TO_DATE(citing."date") >= bp.publication_date
      AND  TO_DATE(citing."date") <= DATEADD(year, 5, bp.publication_date)
    GROUP BY bp.patent_id
)
SELECT bp.patent_id,
       bp."title",
       bp."abstract",
       bp.publication_date,
       COALESCE(b.backward_count, 0) AS backward_citations,
       COALESCE(f.forward_count, 0)  AS forward_citations
FROM   base_patents  bp
       LEFT JOIN backward_cites b ON bp.patent_id = b.patent_id
       LEFT JOIN forward_cites  f ON bp.patent_id = f.patent_id
ORDER  BY bp.publication_date NULLS LAST;