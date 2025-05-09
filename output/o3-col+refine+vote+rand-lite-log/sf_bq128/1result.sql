/*  Patents filed (application date) between 2014-01-01 and 2014-02-01 (US only)
    – title, abstract, publication date
    – # backward patent citations made *before* the filing date
    – # forward patent citations received within 5 years after publication      */

WITH filing_window AS (            -- earliest filing date per patent in window
    SELECT
        "patent_id",
        MIN("date") AS "filing_date"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    GROUP BY "patent_id"
    HAVING MIN("date") >= '2014-01-01'
       AND MIN("date") <  '2014-02-02'
),

/* ---------- backward-citation count -------------------------------------- */
backward AS (
    SELECT
        u."patent_id",
        COUNT(DISTINCT u."citation_id") AS "backward_citations"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION   u
    JOIN filing_window                             fw  ON fw."patent_id" = u."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW.PATENT            pc  ON pc."id" = u."citation_id"
    WHERE pc."date" < fw."filing_date"                    -- cited patent published before filing
    GROUP BY u."patent_id"
),

/* ---------- forward-citation count (within 5 years of publication) -------- */
forward AS (
    SELECT
        l."citation_id" AS "patent_id",
        COUNT(DISTINCT l."patent_id") AS "forward_citations_5y"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION   l   -- link: citing → cited
    JOIN PATENTSVIEW.PATENTSVIEW.PATENT             p0  ON p0."id" = l."citation_id"  -- focal patent
    JOIN PATENTSVIEW.PATENTSVIEW.PATENT             pf  ON pf."id" = l."patent_id"    -- citing patent
    WHERE pf."date" >= p0."date"                                -- after (or on) publication
      AND pf."date" <= DATEADD(year, 5, p0."date")              -- within 5-year window
    GROUP BY l."citation_id"
)

/* ---------- final result -------------------------------------------------- */
SELECT
    p."id"        AS "patent_id",
    p."title",
    p."abstract",
    p."date"      AS "publication_date",
    COALESCE(b."backward_citations", 0)     AS "backward_citations",
    COALESCE(f."forward_citations_5y", 0)   AS "forward_citations_5y"
FROM filing_window                       fw
JOIN PATENTSVIEW.PATENTSVIEW.PATENT      p  ON p."id" = fw."patent_id"
LEFT JOIN backward                       b  ON b."patent_id" = p."id"
LEFT JOIN forward                        f  ON f."patent_id" = p."id"
WHERE p."country" = 'US';