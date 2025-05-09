WITH "BASE_PATS" AS (
    SELECT DISTINCT
           p."id"                             AS "patent_id",
           p."title",
           p."abstract",
           p."date"                           AS "publication_date",
           a."date"                           AS "filing_date"
    FROM   PATENTSVIEW.PATENTSVIEW.PATENT          p
           JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION a
                 ON a."patent_id" = p."id"
           JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT c
                 ON c."patent_id" = p."id"
    WHERE  p."country" = 'US'
      AND  a."date" >= '2014-01-01'
      AND  a."date" <  '2014-02-02'          -- up to and including 2014-02-01
      AND ( c."subsection_id" IN ('C05','C06','C07','C08','C09','C10','C11','C12','C13')
             OR c."group_id" IN ('A01G','A01H','A61K','A61P','A61Q',
                                 'B01F','B01J','B81B','B82B','B82Y',
                                 'G01N','G16H') )
),

"BACKWARD" AS (
    SELECT bp."patent_id",
           COUNT(DISTINCT uc."citation_id")  AS "backward_cnt"
    FROM   "BASE_PATS" bp
           JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
                 ON uc."patent_id" = bp."patent_id"
           LEFT JOIN PATENTSVIEW.PATENTSVIEW.PATENT cited
                 ON cited."id" = uc."citation_id"
    WHERE  cited."date" < bp."filing_date"   -- cited patent published before filing
    GROUP BY bp."patent_id"
),

"FORWARD" AS (
    SELECT bp."patent_id",
           COUNT(DISTINCT uc."patent_id")    AS "forward_cnt"
    FROM   "BASE_PATS" bp
           JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
                 ON uc."citation_id" = bp."patent_id"      -- our patent is being cited
           JOIN PATENTSVIEW.PATENTSVIEW.PATENT citing
                 ON citing."id" = uc."patent_id"
    WHERE  citing."date" <= DATEADD('year', 5, bp."publication_date")  -- within 5-year window
      AND  citing."date" >= bp."publication_date"
    GROUP BY bp."patent_id"
)

SELECT bp."patent_id",
       bp."title",
       bp."abstract",
       bp."publication_date",
       COALESCE(b."backward_cnt", 0)          AS "backward_citations",
       COALESCE(f."forward_cnt", 0)           AS "forward_citations_5yrs"
FROM   "BASE_PATS" bp
       LEFT JOIN "BACKWARD" b ON b."patent_id" = bp."patent_id"
       LEFT JOIN "FORWARD"  f ON f."patent_id" = bp."patent_id"
ORDER  BY bp."publication_date" NULLS LAST,
          bp."patent_id";