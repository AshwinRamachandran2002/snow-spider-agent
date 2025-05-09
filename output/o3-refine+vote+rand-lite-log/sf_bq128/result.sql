WITH selected_patents AS (

    /*------------------------------------------------------------------*
     * 1.  U.S. patent applications filed between 1‑Jan‑2014 and         *
     *     1‑Feb‑2014 (inclusive) whose CPC classification is either     *
     *     C05 … C13 or in the explicit chemistry / bio / medical list. *
     *------------------------------------------------------------------*/
    SELECT  DISTINCT
            p."id"                       AS "patent_id",
            p."title"                    AS "title",
            p."abstract"                 AS "abstract",
            p."date"                     AS "pub_date",      -- grant / publication date
            a."date"                     AS "filing_date"
    FROM    PATENTSVIEW.PATENTSVIEW.PATENT      p
    JOIN    PATENTSVIEW.PATENTSVIEW.APPLICATION a
           ON a."patent_id" = p."id"
    JOIN    PATENTSVIEW.PATENTSVIEW.CPC_CURRENT c
           ON c."patent_id" = p."id"
    WHERE   a."country" = 'US'
      AND   a."date" BETWEEN '2014-01-01' AND '2014-02-01'
      AND   p."country" = 'US'
      AND (  ( c."section_id" = 'C'
                AND TRY_TO_NUMBER(SUBSTR(c."subsection_id",2)) BETWEEN 5 AND 13 )
           OR c."group_id" IN ( 'A01G','A01H','A61K','A61P','A61Q',
                                'B01F','B01J','B81B','B82B','B82Y',
                                'G01N','G16H' )
          )
),

/*------------------------------------------------------------------*
 * 2.  Backward citations (references to earlier patents).           *
 *------------------------------------------------------------------*/
backward AS (
    SELECT  uc."patent_id"                      AS "patent_id",
            COUNT(DISTINCT uc."citation_id")    AS "back_cnt"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN    selected_patents sp
           ON sp."patent_id" = uc."patent_id"
    WHERE   uc."date" < sp."filing_date"
    GROUP BY uc."patent_id"
),

/*------------------------------------------------------------------*
 * 3.  Forward citations within five years of publication.           *
 *------------------------------------------------------------------*/
forward AS (
    SELECT  uc."citation_id"                    AS "patent_id",
            COUNT(DISTINCT uc."patent_id")      AS "fwd_cnt_5y"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN    PATENTSVIEW.PATENTSVIEW.PATENT citing
           ON citing."id" = uc."patent_id"            -- citing (later) patent
    JOIN    selected_patents cited
           ON cited."patent_id" = uc."citation_id"    -- focal patent
    WHERE   citing."date"  >  cited."pub_date"
      AND   citing."date" <= DATEADD(year, 5, cited."pub_date")
    GROUP BY uc."citation_id"
)

/*------------------------------------------------------------------*
 * 4.  Assemble final result.                                        *
 *------------------------------------------------------------------*/
SELECT  sp."patent_id"                             AS "patent_id",
        sp."title"                                 AS "title",
        sp."abstract"                              AS "abstract",
        sp."pub_date"                              AS "publication_date",
        COALESCE(bw."back_cnt", 0)                 AS "backward_citation_count",
        COALESCE(fw."fwd_cnt_5y", 0)               AS "forward_citation_count_5y"
FROM    selected_patents  sp
LEFT JOIN backward        bw  ON bw."patent_id" = sp."patent_id"
LEFT JOIN forward         fw  ON fw."patent_id" = sp."patent_id"
ORDER BY sp."pub_date", sp."patent_id";