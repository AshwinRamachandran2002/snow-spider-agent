WITH
/* -----------------------------------------------------------------
   Patents of interest: U.S. applications filed 2014-01-01 → 2014-02-01
   that belong to chemistry / biology / medical CPC classes
-------------------------------------------------------------------*/
PATENTS AS (
    SELECT DISTINCT
        p."id"                                            AS "patent_id",
        p."title",
        p."abstract",
        TRY_TO_DATE(p."date")                            AS "pub_date",
        TRY_TO_DATE(a."date")                            AS "filing_date"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT        p
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION   a  ON a."patent_id" = p."id"
    JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT   c  ON c."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND TRY_TO_DATE(a."date") BETWEEN '2014-01-01' AND '2014-02-01'
      AND (
              (c."section_id" = 'C'
               AND TO_NUMBER(SUBSTR(c."subsection_id",2)) BETWEEN 5 AND 13)
           OR c."group_id" IN ('A01G','A01H','A61K','A61P','A61Q',
                               'B01F','B01J','B81B','B82B','B82Y',
                               'G01N','G16H')
          )
),

/* ---------------------------------------------------------------
   Backward citations (cited patents) – only those published
   before the current patent’s filing date
-----------------------------------------------------------------*/
BACKWARD AS (
    SELECT
        uc."patent_id"                        AS "patent_id",
        COUNT(DISTINCT uc."citation_id")      AS "backward_citations"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN PATENTS  p  ON p."patent_id" = uc."patent_id"
    WHERE TRY_TO_DATE(uc."date") < p."filing_date"
    GROUP BY uc."patent_id"
),

/* ---------------------------------------------------------------
   Forward citations (citing patents) – only those whose
   publication date lies within 5 years after the current patent’s
   publication date
-----------------------------------------------------------------*/
FORWARD AS (
    SELECT
        uc."citation_id"                      AS "patent_id",
        COUNT(DISTINCT uc."patent_id")        AS "forward_citations_5yr"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN PATENTS           p  ON p."patent_id" = uc."citation_id"
    JOIN PATENTSVIEW.PATENTSVIEW.PATENT citing
         ON citing."id" = uc."patent_id"
    WHERE TRY_TO_DATE(citing."date") >= p."pub_date"
      AND TRY_TO_DATE(citing."date") <= DATEADD(year, 5, p."pub_date")
    GROUP BY uc."citation_id"
)

/* ---------------------------------------------------------------
   Final result
-----------------------------------------------------------------*/
SELECT
    p."patent_id",
    p."title",
    p."abstract",
    p."pub_date"                              AS "publication_date",
    COALESCE(b."backward_citations", 0)       AS "backward_citation_count",
    COALESCE(f."forward_citations_5yr", 0)    AS "forward_citation_count_5yr"
FROM PATENTS p
LEFT JOIN BACKWARD b ON p."patent_id" = b."patent_id"
LEFT JOIN FORWARD  f ON p."patent_id" = f."patent_id"
ORDER BY p."patent_id";