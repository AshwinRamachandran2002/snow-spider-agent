/* =========  Patents in CPC subsection “C05” OR group “A01G”  ========= */
/* ==  Back- and forward-citation counts in the 30-day window          == */
/* ==  around EACH patent’s FIRST U.S. application date               == */

WITH app_first AS (                      /* earliest application date per patent */
    SELECT  "patent_id",
            MIN(TRY_TO_DATE("date")) AS "app_date"
    FROM    PATENTSVIEW.PATENTSVIEW.APPLICATION
    GROUP BY "patent_id"
    HAVING  "app_date" IS NOT NULL
),

cpc_filter AS (                          /* patents that meet CPC requirement   */
    SELECT DISTINCT "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE  "subsection_id" = 'C05'
       OR  "group_id"      = 'A01G'
),

/* ---------- backward citations: patents that THIS patent cites ----- */
bwd_30 AS (
    SELECT  uc."patent_id"               AS "patent_id",
            COUNT(*)                     AS "bwd_30_cnt"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION  uc
    JOIN    app_first                                    af
              ON af."patent_id" = uc."patent_id"
    WHERE   TRY_TO_DATE(uc."date") IS NOT NULL
      AND   TRY_TO_DATE(uc."date") <  af."app_date"                -- earlier
      AND   DATEDIFF('day',
                     TRY_TO_DATE(uc."date"),
                     af."app_date") BETWEEN 1 AND 30               -- ≤30 days
    GROUP BY uc."patent_id"
),

/* ---------- forward citations: patents that cite THIS patent ------- */
fwd_30 AS (
    SELECT  uc."citation_id"             AS "patent_id",
            COUNT(*)                     AS "fwd_30_cnt"
    FROM    PATENTSVIEW.PATENTSVIEW.USPATENTCITATION  uc
    JOIN    app_first                                    af
              ON af."patent_id" = uc."citation_id"
    WHERE   TRY_TO_DATE(uc."date") IS NOT NULL
      AND   TRY_TO_DATE(uc."date") >  af."app_date"                -- later
      AND   DATEDIFF('day',
                     af."app_date",
                     TRY_TO_DATE(uc."date")) BETWEEN 1 AND 30      -- ≤30 days
    GROUP BY uc."citation_id"
)

/* ------------------------------ final result ----------------------- */
SELECT  p."id"                               AS "patent_id",
        p."title",
        TO_CHAR(af."app_date",'YYYY-MM-DD')   AS "application_date",
        COALESCE(b."bwd_30_cnt",0)            AS "backward_1m_cnt",
        COALESCE(f."fwd_30_cnt",0)            AS "forward_1m_cnt",
        p."abstract"
FROM            cpc_filter                     cf
JOIN            PATENTSVIEW.PATENTSVIEW.PATENT      p   ON p."id" = cf."patent_id"
JOIN            app_first                           af  ON af."patent_id" = p."id"
LEFT  JOIN      bwd_30                              b   ON b."patent_id"  = p."id"
LEFT  JOIN      fwd_30                              f   ON f."patent_id"  = p."id"
WHERE   COALESCE(b."bwd_30_cnt",0) > 0
     OR COALESCE(f."fwd_30_cnt",0) > 0
ORDER BY af."app_date" NULLS LAST;