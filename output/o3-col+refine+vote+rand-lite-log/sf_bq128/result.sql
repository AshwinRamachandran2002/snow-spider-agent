/*  Patents filed (published) between 2014-01-01 and 2014-02-01
    – title, abstract, publication date
    – # backward citations (to earlier patents)
    – # forward citations received within 5 years of publication          */

WITH focal_patents AS (     -- patents in the required window
    SELECT  p."id",
            p."title",
            p."abstract",
            p."date"
    FROM    PATENTSVIEW.PATENTSVIEW.PATENT  p
    WHERE   p."country" = 'US'
      AND   p."date"    >= '2014-01-01'
      AND   p."date"    <= '2014-02-01'
),

backward AS (               -- cited patents published earlier than the focal patent
    SELECT  uc."patent_id"              AS patent_id,
            COUNT(*)                    AS backward_cnt
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION  uc
    JOIN    PATENTSVIEW.PATENTSVIEW.PATENT             cited
              ON cited."id" = uc."citation_id"
    JOIN    focal_patents  fp
              ON fp."id"   = uc."patent_id"
    WHERE   cited."date" < fp."date"                  -- earlier publication
    GROUP BY uc."patent_id"
),

forward AS (                -- citing patents published ≤ 5 years after the focal patent
    SELECT  uc."citation_id"            AS patent_id,
            COUNT(*)                    AS forward_cnt_5yr
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION  uc
    JOIN    PATENTSVIEW.PATENTSVIEW.PATENT             citing
              ON citing."id" = uc."patent_id"
    JOIN    focal_patents  fp
              ON fp."id"    = uc."citation_id"
    WHERE   citing."date" <= DATEADD(year, 5, fp."date")   -- within 5-year window
    GROUP BY uc."citation_id"
)

SELECT  fp."id"                       AS "patent_id",
        fp."title",
        fp."abstract",
        fp."date"                     AS "publication_date",
        COALESCE(b.backward_cnt, 0)   AS "backward_citation_count",
        COALESCE(f.forward_cnt_5yr,0) AS "forward_citation_count_5yr"
FROM    focal_patents  fp
LEFT JOIN backward      b  ON b.patent_id = fp."id"
LEFT JOIN forward       f  ON f.patent_id = fp."id"
ORDER BY fp."date" ASC, fp."id";