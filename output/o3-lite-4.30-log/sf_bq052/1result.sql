WITH cpc_filter AS (                  /* patents in CPC subsection C05 or group A01G */
    SELECT DISTINCT "patent_id"
    FROM "PATENTSVIEW"."PATENTSVIEW"."CPC_CURRENT"
    WHERE "subsection_id" = 'C05'
       OR "group_id"      = 'A01G'
),
appl AS (                              /* valid application dates              */
    SELECT "patent_id",
           TRY_TO_DATE("date") AS "app_date"
    FROM   "PATENTSVIEW"."PATENTSVIEW"."APPLICATION"
    WHERE  TRY_TO_DATE("date") IS NOT NULL
),
/* ---------- backward citations: patents this patent cites ------------------- */
back AS (
    SELECT  a."patent_id",
            COUNT(*) AS "back_cnt"
    FROM    appl a
    JOIN    "PATENTSVIEW"."PATENTSVIEW"."USPATENTCITATION" c
            ON c."patent_id" = a."patent_id"           -- current patent cites others
    WHERE   TRY_TO_DATE(c."date")
            BETWEEN DATEADD(month,-1,a."app_date")     -- ≤ 1‑month before app date
                AND a."app_date"
    GROUP BY a."patent_id"
),
/* ---------- forward citations: later patents that cite this one ------------- */
fwd AS (
    SELECT  curr."patent_id",
            COUNT(*) AS "fwd_cnt"
    FROM    appl                                curr           -- current patent
    JOIN    "PATENTSVIEW"."PATENTSVIEW"."USPATENTCITATION" c
            ON c."citation_id" = curr."patent_id"             -- other patent cites current
    JOIN    appl                                citing         -- application date of citing patent
            ON citing."patent_id" = c."patent_id"
    WHERE   citing."app_date"
            BETWEEN curr."app_date"                            -- within 1‑month after
                AND DATEADD(month,1,curr."app_date")
    GROUP BY curr."patent_id"
)
/* ============================ FINAL RESULT ================================== */
SELECT  p."id"                                    AS "patent_id",
        p."title",
        a."app_date"                              AS "application_date",
        COALESCE(b."back_cnt",0)                  AS "backward_citations_1m",
        COALESCE(f."fwd_cnt",0)                   AS "forward_citations_1m",
        p."abstract"
FROM    cpc_filter            cf
JOIN    "PATENTSVIEW"."PATENTSVIEW"."PATENT"   p  ON p."id" = cf."patent_id"
JOIN    appl                     a  ON a."patent_id" = p."id"
LEFT    JOIN back                b  ON b."patent_id" = p."id"
LEFT    JOIN fwd                 f  ON f."patent_id" = p."id"
WHERE   p."country" = 'US'                             -- U.S. patents only
  AND  (COALESCE(b."back_cnt",0) > 0                  -- at least one citation in window
        OR COALESCE(f."fwd_cnt",0)  > 0)
ORDER BY a."app_date";