/*  Robust version that skips malformed dates (e.g. 1968-05-00) by relying on
    TRY_TO_DATE, which returns NULL for invalid strings.  Only rows whose
    dates successfully convert to real DATE values are kept.                */

WITH application_dates AS (              -- valid U.S. application dates
    SELECT 
        a."patent_id",
        TRY_TO_DATE(a."date") AS application_date
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION" a
    WHERE a."country" = 'US'
      AND TRY_TO_DATE(a."date") IS NOT NULL
),

patent_grant_dates AS (                  -- valid patent-grant dates
    SELECT 
        p."id"        AS patent_id,
        TRY_TO_DATE(p."date") AS grant_date,
        p."country"
    FROM PATENTSVIEW.PATENTSVIEW."PATENT" p
    WHERE TRY_TO_DATE(p."date") IS NOT NULL
),

cpc_filter AS (                          -- restrict to desired CPC group(s)
    SELECT DISTINCT
        c."patent_id"
    FROM PATENTSVIEW.PATENTSVIEW."CPC_CURRENT" c
    WHERE c."group_id" = 'G06F'          -- adjust CPC grouping here
),

backward_1yr AS (                        -- backward citations ≤ 1 yr before filing
    SELECT
        uc."patent_id"        AS focal_patent,
        COUNT(*)              AS backward_1yr_cnt
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  uc
    JOIN application_dates            ad  ON ad."patent_id" = uc."patent_id"
    JOIN patent_grant_dates           pg  ON pg.patent_id   = uc."citation_id"
    WHERE pg."country" = 'US'
      AND DATEDIFF('day', pg.grant_date, ad.application_date) BETWEEN 0 AND 365
    GROUP BY uc."patent_id"
),

forward_1yr AS (                         -- forward citations ≤ 1 yr after filing
    SELECT
        uc."citation_id"      AS focal_patent,
        COUNT(*)              AS forward_1yr_cnt
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  uc
    JOIN application_dates            ad  ON ad."patent_id" = uc."citation_id"
    JOIN patent_grant_dates           pg  ON pg.patent_id   = uc."patent_id"
    WHERE pg."country" = 'US'
      AND DATEDIFF('day', ad.application_date, pg.grant_date) BETWEEN 0 AND 365
    GROUP BY uc."citation_id"
),

forward_3yr AS (                         -- forward citations ≤ 3 yr after filing
    SELECT
        uc."citation_id"      AS focal_patent,
        COUNT(*)              AS forward_3yr_cnt
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  uc
    JOIN application_dates            ad  ON ad."patent_id" = uc."citation_id"
    JOIN patent_grant_dates           pg  ON pg.patent_id   = uc."patent_id"
    WHERE pg."country" = 'US'
      AND DATEDIFF('day', ad.application_date, pg.grant_date) BETWEEN 0 AND 1095  -- 3 years
    GROUP BY uc."citation_id"
)

SELECT
    p."id"                                AS patent_id,
    p."title",
    b.backward_1yr_cnt,
    f1.forward_1yr_cnt,
    f3.forward_3yr_cnt
FROM backward_1yr                b
JOIN forward_1yr                 f1 ON f1.focal_patent = b.focal_patent
JOIN forward_3yr                 f3 ON f3.focal_patent = b.focal_patent
JOIN cpc_filter                  c  ON c."patent_id"   = b.focal_patent
JOIN PATENTSVIEW.PATENTSVIEW."PATENT" p ON p."id"      = b.focal_patent
ORDER BY b.backward_1yr_cnt DESC NULLS LAST
LIMIT 1;