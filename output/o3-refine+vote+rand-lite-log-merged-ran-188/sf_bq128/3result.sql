/*  Patents filed in the U.S. from 2014-01-01 (inclusive) to 2014-02-01 (inclusive)
    with their title, abstract, publication date, the count of BACKWARD patent
    citations made before the filing date, and the count of FORWARD patent
    citations received within five years after the publication (grant) date.     */

WITH focal_patents AS (          -- filing-window patents
    SELECT
        a."patent_id",
        TRY_TO_DATE(a."date")  AS "filing_date"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION" a
    WHERE a."country" = 'US'
      AND a."date"  >= '2014-01-01'
      AND a."date"  <  '2014-02-02'          -- 2014-02-01 inclusive
),

/* ----------  backward citations (patents that the focal patent cites) ---------- */
backward AS (
    SELECT
        uc."patent_id",
        COUNT(*) AS "backward_cite_cnt"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN focal_patents fp
          ON fp."patent_id" = uc."patent_id"
    WHERE TRY_TO_DATE(uc."date") IS NOT NULL          -- publication date of cited patent
      AND TRY_TO_DATE(uc."date") < fp."filing_date"   -- must be earlier than filing date
    GROUP BY uc."patent_id"
),

/* ----------  forward citations (patents that cite the focal patent) ------------ */
forward AS (
    SELECT
        f."citation_id"       AS "patent_id",
        COUNT(*)              AS "forward_cite_cnt_5yr"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" f
    JOIN PATENTSVIEW.PATENTSVIEW."PATENT" p           -- to fetch focal-patent pub date
          ON p."id" = f."citation_id"
    JOIN focal_patents fp
          ON fp."patent_id" = f."citation_id"
    WHERE TRY_TO_DATE(f."date") IS NOT NULL           -- publication date of citing patent
      AND TRY_TO_DATE(p."date") IS NOT NULL
      AND TRY_TO_DATE(f."date") >= TRY_TO_DATE(p."date")                    -- after pub
      AND TRY_TO_DATE(f."date") <= DATEADD(year, 5, TRY_TO_DATE(p."date"))  -- ≤5 yrs
    GROUP BY f."citation_id"
)

/* ---------------------------  final result set  ------------------------------- */
SELECT
    fp."patent_id",
    p."title",
    p."abstract",
    p."date"                               AS "publication_date",
    COALESCE(b."backward_cite_cnt", 0)     AS "backward_cite_cnt",
    COALESCE(f."forward_cite_cnt_5yr", 0)  AS "forward_cite_cnt_5yr"
FROM focal_patents  fp
JOIN PATENTSVIEW.PATENTSVIEW."PATENT" p
      ON p."id" = fp."patent_id"
LEFT JOIN backward b
      ON b."patent_id" = fp."patent_id"
LEFT JOIN forward  f
      ON f."patent_id" = fp."patent_id"
ORDER BY fp."patent_id";