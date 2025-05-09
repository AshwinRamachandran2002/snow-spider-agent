/*  Patents in CPC subsection “C05*” (FERTILISERS) or group “A01G*” (GARDENING),   
    plus their one-month backward & forward citation counts.                    */

WITH app AS (      -- earliest valid application-date for every patent
    SELECT
        "patent_id",
        MIN(TRY_TO_DATE("date")) AS app_dt
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE TRY_TO_DATE("date") IS NOT NULL
    GROUP BY "patent_id"
),
cpc_ok AS (        -- patents that meet the requested CPC filters
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE  "group_id"      ILIKE 'C05%'      -- any C05- group
       OR "group_id"      ILIKE 'A01G%'     -- any A01G- group
       OR "subsection_id"  =    'C05'       -- safety net for pure subsection tag
),
back AS (          -- backward citations ≤30 days BEFORE application
    SELECT
        uc."patent_id",
        COUNT(DISTINCT uc."citation_id") AS backward_1m
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN app a ON a."patent_id" = uc."patent_id"
    WHERE TRY_TO_DATE(uc."date")             IS NOT NULL
      AND TRY_TO_DATE(uc."date") >= DATEADD(day,-30,a.app_dt)
      AND TRY_TO_DATE(uc."date")  <  a.app_dt
    GROUP BY uc."patent_id"
),
fwd AS (           -- forward citations ≤30 days AFTER application
    SELECT
        uc."citation_id"               AS "patent_id",
        COUNT(DISTINCT uc."patent_id") AS forward_1m
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN app a ON a."patent_id" = uc."citation_id"
    WHERE TRY_TO_DATE(uc."date")             IS NOT NULL
      AND TRY_TO_DATE(uc."date")  >  a.app_dt
      AND TRY_TO_DATE(uc."date") <= DATEADD(day, 30, a.app_dt)
    GROUP BY uc."citation_id"
)
SELECT
    p."id"                         AS patent_id,
    p."title",
    a.app_dt                       AS application_date,
    COALESCE(b.backward_1m, 0)     AS backward_1m,
    COALESCE(f.forward_1m, 0)      AS forward_1m,
    p."abstract"
FROM PATENTSVIEW.PATENTSVIEW."PATENT" p
JOIN app      a  ON a."patent_id" = p."id"
JOIN cpc_ok   c  ON c."patent_id" = p."id"
LEFT JOIN back b ON b."patent_id" = p."id"
LEFT JOIN fwd  f ON f."patent_id" = p."id"
WHERE COALESCE(b.backward_1m,0) > 0
   OR COALESCE(f.forward_1m,0) > 0
ORDER BY a.app_dt;