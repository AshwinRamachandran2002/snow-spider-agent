/*  Patents in CPC subsection 'C05' or CPC group 'A01G'
    – include patent id, title, application date,
      1-month “backward” & “forward” citation counts,
      and abstract.
    – keep only U.S. patents having ≥1 such citation.
*/

WITH cpc_filter AS (      -- patents in the requested CPC buckets
    SELECT DISTINCT
           "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE  "subsection_id" = 'C05'
       OR  "group_id"      = 'A01G'
),

/* citations that REFERENCE the focal patent ≤30 days BEFORE its
   application date (i.e., citations *to* the patent)            */
bwd AS (
    SELECT
        cit."citation_id"               AS "patent_id",
        COUNT(*)                        AS "backward_cite_1m"
    FROM   PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" cit
    JOIN   PATENTSVIEW.PATENTSVIEW."APPLICATION"      app
           ON cit."citation_id" = app."patent_id"
    WHERE  TRY_TO_DATE(cit."date") IS NOT NULL
      AND  TRY_TO_DATE(app."date") IS NOT NULL
      AND  DATEDIFF('day',
                    TRY_TO_DATE(cit."date"),
                    TRY_TO_DATE(app."date")) BETWEEN 0 AND 30
    GROUP BY cit."citation_id"
),

/* citations that the focal patent MAKES ≤30 days AFTER its
   application date (i.e., citations *from* the patent)           */
fwd AS (
    SELECT
        cit."patent_id"                 AS "patent_id",
        COUNT(*)                        AS "forward_cite_1m"
    FROM   PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" cit
    JOIN   PATENTSVIEW.PATENTSVIEW."APPLICATION"      app
           ON cit."patent_id" = app."patent_id"
    WHERE  TRY_TO_DATE(cit."date") IS NOT NULL
      AND  TRY_TO_DATE(app."date") IS NOT NULL
      AND  DATEDIFF('day',
                    TRY_TO_DATE(app."date"),
                    TRY_TO_DATE(cit."date")) BETWEEN 0 AND 30
    GROUP BY cit."patent_id"
)

SELECT
       p."id"                                         AS "patent_id",
       p."title",
       app."date"                                     AS "application_date",
       COALESCE(b."backward_cite_1m", 0)              AS "backward_cite_1m",
       COALESCE(f."forward_cite_1m", 0)               AS "forward_cite_1m",
       p."abstract"
FROM   PATENTSVIEW.PATENTSVIEW."PATENT"      p
JOIN   PATENTSVIEW.PATENTSVIEW."APPLICATION" app
       ON p."id" = app."patent_id"
JOIN   cpc_filter                             c
       ON p."id" = c."patent_id"
LEFT  JOIN bwd                                 b
       ON p."id" = b."patent_id"
LEFT  JOIN fwd                                 f
       ON p."id" = f."patent_id"
WHERE  p."country" = 'US'
  AND  ( COALESCE(b."backward_cite_1m",0) > 0
      OR COALESCE(f."forward_cite_1m",0)  > 0 )
ORDER BY TRY_TO_DATE(app."date")
;