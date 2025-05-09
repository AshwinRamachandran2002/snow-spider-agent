WITH patents_in_window AS (          -- 1) target U.S. patents filed 2014-01-01 – 2014-02-01
    SELECT
        p."id"                         AS "patent_id",
        p."title",
        p."abstract",
        TO_DATE(p."date")              AS "publication_date",
        TO_DATE(a."date")              AS "application_date"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT      p
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION a
          ON p."id" = a."patent_id"
    WHERE TO_DATE(a."date") BETWEEN '2014-01-01' AND '2014-02-01'
      AND p."country" = 'US'
),
backward AS (                         -- 2) backward-citation count (cited before filing date)
    SELECT
        c."patent_id",
        COUNT(DISTINCT c."citation_id") AS "backward_citations"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION  c
    JOIN patents_in_window pw
          ON pw."patent_id" = c."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW.PATENT  cited
          ON cited."id" = c."citation_id"
    WHERE TO_DATE(cited."date") < pw."application_date"
    GROUP BY c."patent_id"
),
forward AS (                          -- 3) forward-citation count within 5 yrs of publication
    SELECT
        c."citation_id"                AS "patent_id",
        COUNT(DISTINCT c."patent_id")  AS "forward_citations_5y"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION  c
    JOIN patents_in_window pw
          ON pw."patent_id" = c."citation_id"
    JOIN PATENTSVIEW.PATENTSVIEW.PATENT  citing
          ON citing."id" = c."patent_id"
    WHERE TO_DATE(citing."date") <= DATEADD(year, 5, pw."publication_date")
    GROUP BY c."citation_id"
)
SELECT
    pw."patent_id",
    pw."title",
    pw."abstract",
    pw."publication_date",
    COALESCE(b."backward_citations", 0)      AS "backward_citations",
    COALESCE(f."forward_citations_5y", 0)    AS "forward_citations_5y"
FROM patents_in_window pw
LEFT JOIN backward b ON pw."patent_id" = b."patent_id"
LEFT JOIN forward  f ON pw."patent_id" = f."patent_id"
ORDER BY pw."publication_date", pw."patent_id";