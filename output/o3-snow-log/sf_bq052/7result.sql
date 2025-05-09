/*  Patents in CPC subsection ‘C05’ or group ‘A01G’
    having ≥ 1 backward citation within 1-month before filing
    or ≥ 1 forward citation within 1-month after filing.         */

WITH app AS (      /* clean & keep earliest valid application date */
    SELECT  "patent_id",
            MIN(app_date)                AS "application_date"
    FROM   (
            SELECT  "patent_id",
                    TRY_TO_DATE("date")  AS app_date
            FROM    PATENTSVIEW.PATENTSVIEW.APPLICATION
           ) a
    WHERE  app_date IS NOT NULL
    GROUP BY "patent_id"
),

cpc AS (           /* patents in requested CPC categories */
    SELECT DISTINCT "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE  "subsection_id" = 'C05'
       OR  "group_id"      = 'A01G'
),

backward AS (      /* citations MADE BY focal patent ≤ 1 month before filing */
    SELECT  c."patent_id",
            COUNT(*)        AS "backward_cnt"
    FROM   (
            SELECT  "patent_id",
                    TRY_TO_DATE("date") AS cite_date
            FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION
           ) c
    JOIN   app  a  ON a."patent_id" = c."patent_id"
    WHERE  c.cite_date IS NOT NULL
      AND  c.cite_date >= DATEADD(month,-1,a."application_date")
      AND  c.cite_date <= a."application_date"
    GROUP BY c."patent_id"
),

forward AS (       /* citations RECEIVED BY focal patent ≤ 1 month after filing */
    SELECT  c."citation_id"             AS "patent_id",
            COUNT(*)                    AS "forward_cnt"
    FROM   (
            SELECT  "citation_id",
                    TRY_TO_DATE("date") AS cite_date
            FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION
           ) c
    JOIN   app  a  ON a."patent_id" = c."citation_id"
    WHERE  c.cite_date IS NOT NULL
      AND  c.cite_date >= a."application_date"
      AND  c.cite_date <= DATEADD(month,1,a."application_date")
    GROUP BY c."citation_id"
)

SELECT  p."id"                              AS "patent_id",
        p."title",
        a."application_date",
        COALESCE(b."backward_cnt",0)        AS "backward_citations_1m",
        COALESCE(f."forward_cnt",0)         AS "forward_citations_1m",
        p."abstract"
FROM    PATENTSVIEW.PATENTSVIEW.PATENT      p
JOIN    app        a   ON a."patent_id" = p."id"
JOIN    cpc            ON cpc."patent_id" = p."id"
LEFT JOIN backward  b  ON b."patent_id"  = p."id"
LEFT JOIN forward   f  ON f."patent_id"  = p."id"
WHERE   COALESCE(b."backward_cnt",0) > 0
    OR  COALESCE(f."forward_cnt",0)  > 0
ORDER BY a."application_date";