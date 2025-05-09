/*---------------------------------------------------------------
  Patents in CPC subsection 'C05' or group 'A01G' together with
  1-month-window backward / forward citation counts.
  Invalid dates such as YYYY-MM-00 are ignored via TRY_TO_DATE().
----------------------------------------------------------------*/
WITH app_dates AS (          /* earliest valid application date */
    SELECT
        "patent_id",
        MIN( TRY_TO_DATE("date") ) AS "application_date"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE TRY_TO_DATE("date") IS NOT NULL
    GROUP BY "patent_id"
    HAVING MIN( TRY_TO_DATE("date") ) IS NOT NULL
),

/* citations MADE BY the focal patent in the 30-day window before
   its application date                                             */
backward AS (
    SELECT
        c."patent_id",
        COUNT(*) AS "backward_count"
    FROM (
        SELECT
            "patent_id",
            TRY_TO_DATE("date") AS "citation_date"
        FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION
        WHERE TRY_TO_DATE("date") IS NOT NULL
    ) c
    JOIN app_dates a
      ON a."patent_id" = c."patent_id"
    WHERE c."citation_date" >= DATEADD(day, -30, a."application_date")
      AND c."citation_date"  <  a."application_date"
    GROUP BY c."patent_id"
),

/* citations RECEIVED BY the focal patent in the 30-day window
   after its application date                                        */
forward AS (
    SELECT
        c."citation_id" AS "patent_id",
        COUNT(*)        AS "forward_count"
    FROM (
        SELECT
            "citation_id",
            TRY_TO_DATE("date") AS "citation_date"
        FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION
        WHERE TRY_TO_DATE("date") IS NOT NULL
    ) c
    JOIN app_dates a
      ON a."patent_id" = c."citation_id"
    WHERE c."citation_date" >  a."application_date"
      AND c."citation_date" <= DATEADD(day, 30, a."application_date")
    GROUP BY c."citation_id"
),

/* patents that are in CPC subsection C05 or group A01G             */
cpc_filtered AS (
    SELECT DISTINCT
        cc."patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT cc
    WHERE cc."subsection_id" = 'C05'
       OR cc."group_id"      = 'A01G'
)

/*-------------------------- final result -------------------------*/
SELECT
    p."id"                       AS "patent_id",
    p."title",
    a."application_date",
    COALESCE(b."backward_count", 0) AS "backward_citations_1m_before",
    COALESCE(f."forward_count",  0) AS "forward_citations_1m_after",
    p."abstract"
FROM PATENTSVIEW.PATENTSVIEW.PATENT p
JOIN cpc_filtered  cf ON cf."patent_id" = p."id"
JOIN app_dates     a  ON a."patent_id"  = p."id"
LEFT JOIN backward b  ON b."patent_id"  = p."id"
LEFT JOIN forward  f  ON f."patent_id"  = p."id"
WHERE COALESCE(b."backward_count",0) > 0
   OR COALESCE(f."forward_count",0)  > 0
ORDER BY a."application_date" ASC NULLS LAST;