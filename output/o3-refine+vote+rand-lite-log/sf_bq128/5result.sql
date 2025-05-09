/*====================================================================
  U.S. patents filed 2014‑01‑01 through 2014‑02‑01 in chem/bio/med CPC.
  Returns  title, abstract, publication date,
           # backward citations (before filing date) and
           # forward citations in first 5 years after publication.
====================================================================*/
WITH filtered_patents AS (   /* 1. patents in the desired filing window */
    SELECT  p."id"                                   AS patent_id ,
            p."title",
            p."abstract",
            TRY_TO_DATE(p."date")                    AS publication_date ,
            TRY_TO_DATE(a."date")                    AS filing_date
    FROM    PATENTSVIEW.PATENTSVIEW.PATENT      p
    JOIN    PATENTSVIEW.PATENTSVIEW.APPLICATION  a
           ON a."patent_id" = p."id"
    WHERE   p."country"        = 'US'
      AND   TRY_TO_DATE(a."date") >= '2014-01-01'
      AND   TRY_TO_DATE(a."date") <  '2014-02-02'      -- inclusive 02‑01
      AND   TRY_TO_DATE(p."date") IS NOT NULL
      AND   TRY_TO_DATE(a."date") IS NOT NULL
),

/* 2. keep only chemistry / biology / medical CPC */
cpc_ok AS (
    SELECT DISTINCT c."patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW.CPC_CURRENT c
    WHERE  c."subsection_id" IN ('C05','C06','C07','C08','C09',
                                 'C10','C11','C12','C13')
       OR  c."group_id"      IN ('A01G','A01H','A61K','A61P','A61Q',
                                 'B01F','B01J','B81B','B82B','B82Y',
                                 'G01N','G16H')
),

/* 3. candidate patents */
patents AS (
    SELECT fp.*
    FROM   filtered_patents fp
    JOIN   cpc_ok          co  ON co."patent_id" = fp.patent_id
),

/* 4. backward citations (before filing date) */
backward AS (
    SELECT  p.patent_id,
            COUNT(DISTINCT u."citation_id") AS backward_cnt
    FROM    patents p
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
           ON u."patent_id" = p.patent_id
          AND TRY_TO_DATE(u."date") IS NOT NULL
          AND TRY_TO_DATE(u."date") <  p.filing_date
    GROUP BY p.patent_id
),

/* 5. forward citations within 5 years after publication */
forward AS (
    SELECT  p.patent_id,
            COUNT(DISTINCT u."patent_id") AS forward_cnt
    FROM    patents p
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
           ON u."citation_id" = p.patent_id
          AND TRY_TO_DATE(u."date") IS NOT NULL
          AND TRY_TO_DATE(u."date") <= DATEADD(year, 5, p.publication_date)
    GROUP BY p.patent_id
)

/* 6. final result */
SELECT  p.patent_id,
        p."title",
        p."abstract",
        p.publication_date,
        COALESCE(b.backward_cnt, 0) AS backward_citations,
        COALESCE(f.forward_cnt , 0) AS forward_citations_5yrs
FROM    patents p
LEFT JOIN backward b ON b.patent_id = p.patent_id
LEFT JOIN forward  f ON f.patent_id = p.patent_id
ORDER BY p.publication_date,
         p.patent_id;