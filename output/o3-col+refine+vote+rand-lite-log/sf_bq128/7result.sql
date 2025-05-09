WITH filing_window AS (   -- U.S. patents filed 2014-01-01 … 2014-02-01
    SELECT  a."patent_id",
            TRY_TO_DATE(a."date")                       AS "filing_date"
    FROM    PATENTSVIEW.PATENTSVIEW."APPLICATION" a
    JOIN    PATENTSVIEW.PATENTSVIEW."PATENT"      p
           ON p."id" = a."patent_id"
    WHERE   p."country" = 'US'
      AND   TRY_TO_DATE(a."date") BETWEEN '2014-01-01' AND '2014-02-01'
),

pub_info AS (           -- title, abstract, publication date
    SELECT  p."id"                                      AS "patent_id",
            p."title",
            p."abstract",
            TRY_TO_DATE(p."date")                       AS "publication_date"
    FROM    PATENTSVIEW.PATENTSVIEW."PATENT" p
    WHERE   TRY_TO_DATE(p."date") IS NOT NULL
),

backward AS (           -- citations made before filing date
    SELECT  u."patent_id",
            COUNT(*)                                   AS "backward_citations"
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" u
    JOIN    filing_window             f  ON f."patent_id" = u."patent_id"
    WHERE   TRY_TO_DATE(u."date") < f."filing_date"
    GROUP BY u."patent_id"
),

forward AS (            -- citations received ≤ 5 years after publication
    SELECT  uc."citation_id"                           AS "patent_id",
            COUNT(*)                                   AS "forward_citations_5y"
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN    pub_info                 pub ON pub."patent_id" = uc."citation_id"
    JOIN    PATENTSVIEW.PATENTSVIEW."PATENT"     cit ON cit."id" = uc."patent_id"
    WHERE   TRY_TO_DATE(cit."date") IS NOT NULL
      AND   TRY_TO_DATE(cit."date")
            <= DATEADD(year, 5, pub."publication_date")
    GROUP BY uc."citation_id"
)

SELECT  f."patent_id",
        p."title",
        p."abstract",
        p."publication_date",
        COALESCE(b."backward_citations", 0)   AS "backward_citations",
        COALESCE(fw."forward_citations_5y",0) AS "forward_citations_5y"
FROM    filing_window          f
JOIN    pub_info               p   ON p."patent_id" = f."patent_id"
LEFT JOIN backward             b   ON b."patent_id" = f."patent_id"
LEFT JOIN forward              fw  ON fw."patent_id" = f."patent_id"
ORDER BY p."publication_date" NULLS LAST;