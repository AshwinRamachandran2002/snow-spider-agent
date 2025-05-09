/*---------------------------------------------------------------
  Retrieve U.S. patents (CPC subsection 'C05' or group 'A01G')
  together with their application date, abstract, and the number
  of citing patents whose own APPLICATION DATE falls within
  ±30 days of the focal patent’s application date.
----------------------------------------------------------------*/
WITH app AS (       /* valid application dates for every patent */
    SELECT
        "patent_id",
        TRY_TO_DATE("date") AS app_dt
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE TRY_TO_DATE("date") IS NOT NULL
)

SELECT
       p."id"                                                     AS patent_id,
       p."title",
       a.app_dt                                                   AS application_date,
       COUNT( DISTINCT CASE                     /* 30‑day window BEFORE */
               WHEN ac.app_dt BETWEEN DATEADD(day,-30, a.app_dt)
                                  AND DATEADD(day,-1 , a.app_dt)
               THEN u."patent_id" END )                           AS backward_citations_1m,
       COUNT( DISTINCT CASE                     /* 30‑day window AFTER  */
               WHEN ac.app_dt BETWEEN DATEADD(day, 1, a.app_dt)
                                  AND DATEADD(day,30, a.app_dt)
               THEN u."patent_id" END )                           AS forward_citations_1m,
       p."abstract"
FROM   PATENTSVIEW.PATENTSVIEW.PATENT          p
JOIN   app                                     a   ON a."patent_id" = p."id"
JOIN   PATENTSVIEW.PATENTSVIEW.CPC_CURRENT     cc  ON cc."patent_id" = p."id"
LEFT  JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION u
                              ON u."citation_id" = p."id"          /* patents that cite p */
LEFT  JOIN app                                   ac ON ac."patent_id" = u."patent_id"  /* citing patents’ app dates */
WHERE  p."country" = 'US'
  AND (cc."subsection_id" = 'C05' OR cc."group_id" = 'A01G')
GROUP BY
       p."id", p."title", a.app_dt, p."abstract"
HAVING
       COUNT( DISTINCT CASE
               WHEN ac.app_dt BETWEEN DATEADD(day,-30, a.app_dt)
                                  AND DATEADD(day,-1 , a.app_dt)
               THEN u."patent_id" END )
     + COUNT( DISTINCT CASE
               WHEN ac.app_dt BETWEEN DATEADD(day, 1, a.app_dt)
                                  AND DATEADD(day,30, a.app_dt)
               THEN u."patent_id" END ) > 0
ORDER BY a.app_dt;