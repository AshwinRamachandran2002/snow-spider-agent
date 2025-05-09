/*  Patents published in the U.S. between 1-Jan-2014 and 1-Feb-2014
    – title, abstract, publication date
    – backward-citation count (only cited patents published earlier)
    – forward-citation count in first five years after publication       */

WITH target_patents AS (         -- patents in the requested window
    SELECT
        p."id"        AS "patent_id",
        p."title",
        p."abstract",
        p."date"      AS "publication_date"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT p
    WHERE p."country" = 'US'
      AND p."date" BETWEEN '2014-01-01' AND '2014-02-01'
),

backward AS (                     -- backwards: patents this patent cites
    SELECT
        u."patent_id"                     AS "patent_id",
        COUNT(DISTINCT u."citation_id")   AS "backward_citations"
    FROM   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
    JOIN   target_patents tp
           ON tp."patent_id" = u."patent_id"
    JOIN   PATENTSVIEW.PATENTSVIEW.PATENT cited
           ON cited."id" = u."citation_id"
    WHERE  cited."date" < tp."publication_date"        -- only earlier docs
    GROUP  BY u."patent_id"
),

forward AS (                      -- forwards: later patents citing this one
    SELECT
        u."citation_id"                  AS "patent_id",
        COUNT(DISTINCT u."patent_id")    AS "forward_citations_5yr"
    FROM   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
    JOIN   target_patents tp
           ON tp."patent_id" = u."citation_id"
    JOIN   PATENTSVIEW.PATENTSVIEW.PATENT citing
           ON citing."id" = u."patent_id"
    WHERE  citing."date" >  tp."publication_date"           -- after pub
      AND  citing."date" <= DATEADD(year, 5, tp."publication_date") -- ≤5 yrs
    GROUP  BY u."citation_id"
)

SELECT
    tp."patent_id",
    tp."title",
    tp."abstract",
    tp."publication_date",
    COALESCE(b."backward_citations", 0)      AS "backward_citations",
    COALESCE(f."forward_citations_5yr", 0)   AS "forward_citations_5yr"
FROM   target_patents tp
LEFT JOIN backward b ON b."patent_id" = tp."patent_id"
LEFT JOIN forward  f ON f."patent_id" = tp."patent_id"
ORDER BY tp."publication_date" ASC, tp."patent_id";