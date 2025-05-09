/*  Patents filed 1-Jan-2014 – 1-Feb-2014 (US, chem/bio/med) with
    publication info, backward- and 5-year forward-citation counts     */

WITH application_2014 AS (                  /* filing window -------------------------- */
    SELECT  "patent_id",
            MIN(app_dt)        AS application_date
    FROM   (SELECT "patent_id",
                   TRY_TO_DATE("date") AS app_dt
            FROM   PATENTSVIEW.PATENTSVIEW."APPLICATION"
            WHERE  "country" = 'US'
              AND  TRY_TO_DATE("date") BETWEEN '2014-01-01' AND '2014-02-01')
    GROUP BY "patent_id"
),

filtered_patents AS (                       /* tech scope & basic data ---------------- */
    SELECT  DISTINCT
            p."id"                          AS patent_id,
            p."title",
            p."abstract",
            TRY_TO_DATE(p."date")           AS publication_date,
            a.application_date
    FROM    PATENTSVIEW.PATENTSVIEW."PATENT"        p
    JOIN    application_2014                         a  ON a."patent_id" = p."id"
    JOIN    PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"    c  ON c."patent_id" = p."id"
    WHERE   p."country" = 'US'
      AND   TRY_TO_DATE(p."date") IS NOT NULL
      AND   a.application_date        IS NOT NULL
      AND  ( ( c."section_id" = 'C'
               AND c."subsection_id" BETWEEN 'C05' AND 'C13' )
             OR c."group_id" IN ( 'A01G','A01H',
                                  'A61K','A61P','A61Q',
                                  'B01F','B01J',
                                  'B81B','B82B','B82Y',
                                  'G01N','G16H' ) )
),

backward AS (                               /* backward citations --------------------- */
    SELECT  u."patent_id"                   AS patent_id,
            COUNT(DISTINCT u."citation_id") AS backward_cnt
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" u
    JOIN    filtered_patents fp  ON fp.patent_id = u."patent_id"
    WHERE   TRY_TO_DATE(u."date") IS NOT NULL
      AND   TRY_TO_DATE(u."date") <= fp.application_date
    GROUP BY u."patent_id"
),

forward AS (                                /* forward citations within 5 years ------- */
    SELECT  u."citation_id"                 AS patent_id,
            COUNT(DISTINCT u."patent_id")   AS forward_cnt
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" u
    JOIN    filtered_patents fp             ON fp.patent_id = u."citation_id"
    JOIN    PATENTSVIEW.PATENTSVIEW."PATENT" pc ON pc."id" = u."patent_id"
    WHERE   TRY_TO_DATE(pc."date") IS NOT NULL
      AND   TRY_TO_DATE(pc."date") >= fp.publication_date
      AND   TRY_TO_DATE(pc."date") <= DATEADD(year, 5, fp.publication_date)
    GROUP BY u."citation_id"
)

/* --------------------------- final result ---------------------------------------- */
SELECT  fp.patent_id,
        fp."title"                     AS title,
        fp."abstract"                  AS abstract,
        fp.publication_date,
        COALESCE(b.backward_cnt, 0)    AS backward_citations,
        COALESCE(f.forward_cnt, 0)     AS forward_citations_5yr
FROM    filtered_patents fp
LEFT JOIN backward b ON b.patent_id = fp.patent_id
LEFT JOIN forward  f ON f.patent_id = fp.patent_id
ORDER BY fp.publication_date NULLS LAST,
         fp.patent_id;