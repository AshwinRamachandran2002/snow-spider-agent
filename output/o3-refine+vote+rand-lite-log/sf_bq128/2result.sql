/*==============================================================
  Patents filed (application date) from 2014‑01‑01 to 2014‑02‑01
  in the requested chemistry / biology / medical CPC domains.
  Uses TRY_TO_DATE to ignore malformed dates such as 1953‑12‑00.
==============================================================*/
WITH base AS (
    SELECT  DISTINCT
            p."id"                                         AS patent_id,
            p."title"                                      AS patent_title,
            p."abstract"                                   AS patent_abstract,
            TRY_TO_DATE(p."date")                          AS publication_date,
            TRY_TO_DATE(a."date")                          AS filing_date
    FROM   PATENTSVIEW.PATENTSVIEW.PATENT        p
    JOIN   PATENTSVIEW.PATENTSVIEW.APPLICATION   a   ON a."patent_id" = p."id"
    JOIN   PATENTSVIEW.PATENTSVIEW.CPC_CURRENT   cpc ON cpc."patent_id" = p."id"
    WHERE  p."country" = 'US'
      AND  TRY_TO_DATE(a."date") BETWEEN '2014-01-01' AND '2014-02-01'
      AND (
             (cpc."section_id" = 'C'
              AND cpc."subsection_id" IN ('C05','C06','C07','C08',
                                          'C09','C10','C11','C12','C13'))
           OR cpc."group_id"       IN ('A01G','A01H','A61K','A61P','A61Q',
                                        'B01F','B01J','B81B','B82B','B82Y',
                                        'G01N','G16H')
          )
      AND  TRY_TO_DATE(p."date") IS NOT NULL                 -- need publication date
      AND  TRY_TO_DATE(a."date") IS NOT NULL                 -- need filing date
),  /*---------------------------------------------------------
      Backward citations (references published before filing)
     ---------------------------------------------------------*/
backward AS (
    SELECT  b.patent_id,
            COUNT(bc."citation_id") AS backward_cnt
    FROM    base                                   b
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION  bc
           ON bc."patent_id" = b.patent_id
          AND TRY_TO_DATE(bc."date") < b.filing_date
    GROUP BY b.patent_id
), /*---------------------------------------------------------
      Forward citations within 5 years after publication
     ---------------------------------------------------------*/
forward AS (
    SELECT  b.patent_id,
            COUNT(DISTINCT fc."patent_id") AS forward_cnt_5y
    FROM    base                                   b
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION   fc
           ON fc."citation_id" = b.patent_id      -- fc.patent_id cites b.patent_id
    LEFT JOIN PATENTSVIEW.PATENTSVIEW.PATENT            pc
           ON pc."id" = fc."patent_id"             -- publication data of citing patent
    WHERE   TRY_TO_DATE(pc."date") IS NOT NULL
      AND   TRY_TO_DATE(pc."date") <= DATEADD(year, 5, b.publication_date)
    GROUP BY b.patent_id
)
/*-------------------------------------------------------------
  Final combined output
-------------------------------------------------------------*/
SELECT  b.patent_id                    AS "PATENT_ID",
        b.patent_title                 AS "TITLE",
        b.patent_abstract              AS "ABSTRACT",
        b.publication_date             AS "PUBLICATION_DATE",
        COALESCE(bw.backward_cnt, 0)   AS "BACKWARD_CITATIONS",
        COALESCE(fw.forward_cnt_5y, 0) AS "FORWARD_CITATIONS_5Y"
FROM    base        b
LEFT JOIN backward  bw ON bw.patent_id = b.patent_id
LEFT JOIN forward   fw ON fw.patent_id = b.patent_id
ORDER BY b.publication_date, b.patent_id;