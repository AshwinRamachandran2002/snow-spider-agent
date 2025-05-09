/*  PatentsView – U.S. patents filed 1‑Jan‑2014 to 1‑Feb‑2014 in selected CPC
    chemistry / biology / medical fields, with backward and 5‑year forward
    citation counts                                                    */

WITH base AS (       /* patents that satisfy filing‑date, country & CPC filters */
    SELECT
        p."id"                         AS patent_id,
        p."title",
        p."abstract",
        p."date"                       AS publication_date,          -- grant / publication
        MIN(a."date")                  AS filing_date
    FROM PATENTSVIEW.PATENTSVIEW."PATENT"            p
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION"       a   ON a."patent_id" = p."id"
    JOIN PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"       c   ON c."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND a."date" BETWEEN '2014-01-01' AND '2014-02-01'
      AND (
              c."subsection_id" IN ('C05','C06','C07','C08','C09','C10','C11','C12','C13')
              OR c."group_id"   IN ('A01G','A01H','A61K','A61P','A61Q',
                                   'B01F','B01J','B81B','B82B','B82Y',
                                   'G01N','G16H')
          )
    GROUP BY p."id", p."title", p."abstract", p."date"
),

backward AS (        /* patents this patent cites, published BEFORE its filing */
    SELECT
        b.patent_id,
        COUNT(*)     AS backward_citations
    FROM base                                b
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  uc ON uc."patent_id" = b.patent_id
    JOIN PATENTSVIEW.PATENTSVIEW."PATENT"           pc ON pc."id"        = uc."citation_id"
    WHERE pc."date" < b.filing_date
    GROUP BY b.patent_id
),

forward AS (         /* patents that cite this patent within 5 years of grant */
    SELECT
        b.patent_id,
        COUNT(*)     AS forward_citations_5y
    FROM base                                b
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  uc ON uc."citation_id" = b.patent_id
    JOIN PATENTSVIEW.PATENTSVIEW."PATENT"           pf ON pf."id"          = uc."patent_id"
    WHERE pf."date" <= DATEADD(year, 5, b.publication_date)
    GROUP BY b.patent_id
)

SELECT
    b.patent_id,
    b."title",
    b."abstract",
    b.publication_date,
    COALESCE(back.backward_citations, 0)      AS backward_citations,
    COALESCE(fwd.forward_citations_5y, 0)     AS forward_citations_5y
FROM base      b
LEFT JOIN backward back ON back.patent_id = b.patent_id
LEFT JOIN forward  fwd  ON fwd.patent_id  = b.patent_id
ORDER BY b.publication_date, b.patent_id;