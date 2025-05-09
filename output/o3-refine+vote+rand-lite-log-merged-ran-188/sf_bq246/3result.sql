WITH  app AS (   -- cleaned application (filing) dates
        SELECT  "patent_id",
                TRY_TO_DATE("date") AS "app_dt"
        FROM    PATENTSVIEW.PATENTSVIEW."APPLICATION"
        WHERE   TRY_TO_DATE("date") IS NOT NULL
),   pub AS (   -- cleaned publication / grant dates
        SELECT  "id" AS "patent_id",
                TRY_TO_DATE("date") AS "pub_dt"
        FROM    PATENTSVIEW.PATENTSVIEW."PATENT"
        WHERE   TRY_TO_DATE("date") IS NOT NULL
),   backward AS (   -- cites made ≤ 1 year before filing (“backward”)
        SELECT  c."patent_id",
                COUNT(*) AS "backward_cnt"
        FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" c
        JOIN    app  a   ON c."patent_id"   = a."patent_id"
        JOIN    pub  p   ON p."patent_id"   = c."citation_id"
        WHERE   p."pub_dt" >= DATEADD(year,-1, a."app_dt")
          AND   p."pub_dt" <  a."app_dt"
        GROUP BY c."patent_id"
),   fwd_1yr AS (   -- cites received ≤ 1 year after filing (filter only)
        SELECT  c."citation_id" AS "patent_id",
                COUNT(*)        AS "fwd_1yr_cnt"
        FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" c
        JOIN    app  a   ON c."citation_id" = a."patent_id"
        JOIN    pub  p   ON p."patent_id"   = c."patent_id"
        WHERE   p."pub_dt" >= a."app_dt"
          AND   p."pub_dt" <  DATEADD(year,1, a."app_dt")
        GROUP BY c."citation_id"
),   fwd_3yr AS (   -- cites received ≤ 3 years after filing (to be reported)
        SELECT  c."citation_id" AS "patent_id",
                COUNT(*)        AS "fwd_3yr_cnt"
        FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" c
        JOIN    app  a   ON c."citation_id" = a."patent_id"
        JOIN    pub  p   ON p."patent_id"   = c."patent_id"
        WHERE   p."pub_dt" >= a."app_dt"
          AND   p."pub_dt" <  DATEADD(year,3, a."app_dt")
        GROUP BY c."citation_id"
),   both_sides AS (   -- patents having BOTH backward & 1-yr forward cites
        SELECT  b."patent_id",
                b."backward_cnt",
                f3."fwd_3yr_cnt"
        FROM    backward  b
        JOIN    fwd_1yr  f1  ON b."patent_id" = f1."patent_id"
        JOIN    fwd_3yr  f3  ON b."patent_id" = f3."patent_id"
),   tech AS (   -- restrict to target CPC subsections
        SELECT  DISTINCT
                bs."patent_id",
                bs."backward_cnt",
                bs."fwd_3yr_cnt"
        FROM    both_sides               bs
        JOIN    PATENTSVIEW.PATENTSVIEW."CPC_CURRENT" cpc
                   ON bs."patent_id" = cpc."patent_id"
        WHERE   cpc."subsection_id" IN ('G06', 'H04')   -- target technologies
)
SELECT  "patent_id",
        "backward_cnt",
        "fwd_3yr_cnt"  AS "forward_cites_3yr"
FROM    tech
ORDER BY "backward_cnt" DESC NULLS LAST
LIMIT 1;