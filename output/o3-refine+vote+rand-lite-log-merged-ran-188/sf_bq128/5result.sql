WITH filed_patents AS (   -- U.S. patents filed between 1-Jan-2014 and 1-Feb-2014
    SELECT
        p."id"                                   AS PATENT_ID,
        p."title"                                AS PATENT_TITLE,
        p."abstract"                             AS PATENT_ABSTRACT,
        TO_DATE(p."date", 'YYYY-MM-DD')          AS PUBLICATION_DATE,
        TO_DATE(a."date", 'YYYY-MM-DD')          AS FILING_DATE
    FROM   PATENTSVIEW.PATENTSVIEW.PATENT      p
    JOIN   PATENTSVIEW.PATENTSVIEW.APPLICATION a
           ON p."id" = a."patent_id"
    WHERE  a."country" = 'US'
      AND  a."date" BETWEEN '2014-01-01' AND '2014-02-01'
), backward AS (          -- citations made BY the patent before it was filed
    SELECT
        a."patent_id"                            AS PATENT_ID,
        COUNT(*)                                 AS BACKWARD_CITATIONS
    FROM   PATENTSVIEW.PATENTSVIEW.APPLICATION         a
    JOIN   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION     u
           ON a."patent_id" = u."patent_id"
    WHERE  a."country" = 'US'
      AND  a."date" BETWEEN '2014-01-01' AND '2014-02-01'
      AND  TO_DATE(u."date", 'YYYY-MM-DD') < TO_DATE(a."date", 'YYYY-MM-DD')
    GROUP  BY a."patent_id"
), forward AS (           -- citations RECEIVED within 5 years after publication
    SELECT
        p."id"                                  AS PATENT_ID,
        COUNT(*)                                AS FORWARD_CITATIONS_5Y
    FROM   PATENTSVIEW.PATENTSVIEW.PATENT            p
    JOIN   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION  u
           ON u."citation_id" = p."id"
    WHERE  p."id" IN ( SELECT PATENT_ID FROM filed_patents )
      AND  TO_DATE(u."date", 'YYYY-MM-DD') >= TO_DATE(p."date", 'YYYY-MM-DD')
      AND  TO_DATE(u."date", 'YYYY-MM-DD') <  DATEADD(year, 5, TO_DATE(p."date", 'YYYY-MM-DD'))
    GROUP  BY p."id"
)
SELECT
    f.PATENT_ID,
    f.PATENT_TITLE     AS TITLE,
    f.PATENT_ABSTRACT  AS ABSTRACT,
    f.PUBLICATION_DATE,
    COALESCE(b.BACKWARD_CITATIONS ,0)  AS BACKWARD_CITATIONS,
    COALESCE(w.FORWARD_CITATIONS_5Y,0) AS FORWARD_CITATIONS_5Y
FROM   filed_patents f
LEFT   JOIN backward b ON b.PATENT_ID = f.PATENT_ID
LEFT   JOIN forward  w ON w.PATENT_ID = f.PATENT_ID
ORDER  BY w.FORWARD_CITATIONS_5Y DESC NULLS LAST,
          f.PATENT_ID;