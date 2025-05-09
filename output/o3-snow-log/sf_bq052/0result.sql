/*------------------------------------------------------------
   Return U.S. patents (CPC subsection = 'C05'  OR  group = 'A01G')
   together with
      • # backward citations made within 1 month BEFORE application date
      • # forward citations received within 1 month AFTER application date
   Keep only patents that have at least one such citation.
-------------------------------------------------------------*/
WITH app AS (   /* earliest valid U.S. application date --------------------*/
    SELECT
        "patent_id",
        MIN(TRY_TO_DATE("date")) AS application_date
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE "country" = 'US'
      AND TRY_TO_DATE("date") IS NOT NULL
    GROUP BY "patent_id"
), cpc_ok AS (  /* patents in requested CPC classes ------------------------*/
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "subsection_id" = 'C05'
       OR "group_id"      = 'A01G'
), back AS (     /* backward citations (patent cites others) ---------------*/
    SELECT
        a."patent_id",
        COUNT(*) AS backward_citations_1m
    FROM   app a
    JOIN   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
           ON c."patent_id" = a."patent_id"                        -- outgoing
    WHERE  TRY_TO_DATE(c."date") IS NOT NULL
      AND  TRY_TO_DATE(c."date")
           BETWEEN DATEADD(month,-1,a.application_date)
               AND a.application_date
    GROUP BY a."patent_id"
), fwd AS (      /* forward citations (others cite the patent) -------------*/
    SELECT
        a."patent_id",
        COUNT(*) AS forward_citations_1m
    FROM   app a
    JOIN   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
           ON c."citation_id" = a."patent_id"                    -- incoming
    WHERE  TRY_TO_DATE(c."date") IS NOT NULL
      AND  TRY_TO_DATE(c."date") >  a.application_date
      AND  TRY_TO_DATE(c."date") <= DATEADD(month,1,a.application_date)
    GROUP BY a."patent_id"
), counts AS (   /* combine citation counts --------------------------------*/
    SELECT
        a."patent_id",
        COALESCE(b.backward_citations_1m,0) AS backward_citations_1m,
        COALESCE(f.forward_citations_1m ,0) AS forward_citations_1m,
        a.application_date
    FROM app a
    LEFT JOIN back b ON b."patent_id" = a."patent_id"
    LEFT JOIN fwd  f ON f."patent_id" = a."patent_id"
), final AS (    /* assemble and filter ------------------------------------*/
    SELECT
        p."id"                               AS patent_id,
        p."title",
        c.application_date,
        c.backward_citations_1m,
        c.forward_citations_1m,
        p."abstract"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT p
    JOIN counts  c   ON c."patent_id" = p."id"
    JOIN cpc_ok  k   ON k."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND (c.backward_citations_1m > 0
           OR c.forward_citations_1m  > 0)
)
SELECT *
FROM   final
ORDER BY application_date NULLS LAST;