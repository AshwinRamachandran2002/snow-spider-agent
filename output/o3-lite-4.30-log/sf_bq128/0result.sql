WITH filing AS (                          -- earliest filing date for each patent
    SELECT
        "patent_id",
        MIN("date") AS filing_date
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    GROUP BY "patent_id"
),
/* -----------------------------------------------------------
   U.S. patents filed 01‑Jan‑2014 – 01‑Feb‑2014
   restricted to chem / bio / medical CPC codes
----------------------------------------------------------- */
target_patents AS (
    SELECT DISTINCT
        p."id",
        p."title",
        p."abstract",
        p."date"                     AS publication_date,
        f.filing_date
    FROM PATENTSVIEW.PATENTSVIEW.PATENT p
    JOIN filing f
          ON f."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND f.filing_date >= '2014-01-01'
      AND f.filing_date <  '2014-02-02'
      AND EXISTS (
            SELECT 1
            FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT c
            WHERE c."patent_id" = p."id"
              AND (
                     c."subsection_id" BETWEEN 'C05' AND 'C13'
                  OR c."group_id" IN ('A01G','A01H','A61K','A61P','A61Q',
                                      'B01F','B01J','B81B','B82B','B82Y',
                                      'G01N','G16H')
                  )
      )
),
/* -----------------------------------------------------------
   Backward citations  (cited patents with pub‑date < filing)
----------------------------------------------------------- */
backward AS (
    SELECT
        u."patent_id",
        COUNT(*) AS backward_citations
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
    JOIN target_patents t
          ON t."id" = u."patent_id"
    WHERE u."date" < t.filing_date
    GROUP BY u."patent_id"
),
/* -----------------------------------------------------------
   Forward citations within 5 years after publication
----------------------------------------------------------- */
fwd AS (
    SELECT
        t."id" AS patent_id,
        COUNT(*) AS forward_citations_5yr
    FROM target_patents                     t
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
          ON u."citation_id" = t."id"
    JOIN PATENTSVIEW.PATENTSVIEW.PATENT cp
          ON cp."id" = u."patent_id"
    WHERE DATEDIFF('day', t.publication_date, cp."date") BETWEEN 0 AND 1825
    GROUP BY t."id"
)
/* -----------------------------------------------------------
   Final result
----------------------------------------------------------- */
SELECT
    t."title"                                           AS "patent_title",
    t."abstract"                                        AS "abstract",
    t.publication_date                                  AS "publication_date",
    COALESCE(b.backward_citations, 0)                   AS "backward_citations",
    COALESCE(f.forward_citations_5yr, 0)                AS "forward_citations_5yr"
FROM target_patents t
LEFT JOIN backward b  ON b."patent_id" = t."id"
LEFT JOIN fwd      f  ON f.patent_id   = t."id"
ORDER BY t.publication_date, t."title";