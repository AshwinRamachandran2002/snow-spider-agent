WITH application_clean AS (             -- cast only valid dates
    SELECT
        "patent_id",
        TRY_TO_DATE("date") AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE TRY_TO_DATE("date") IS NOT NULL
),
app_dates AS (                           -- earliest valid application date
    SELECT
        "patent_id",
        MIN("app_date") AS "app_date"
    FROM application_clean
    GROUP BY "patent_id"
),
cpc_patents AS (                         -- patents in subsection C05 or group A01G
    SELECT DISTINCT
        "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "subsection_id" = 'C05'
       OR "group_id"      = 'A01G'
),
backward_cites AS (                      -- citations ≤1 month before own app date
    SELECT
        uc."patent_id",
        COUNT(DISTINCT uc."citation_id") AS "backward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN app_dates ad_curr  ON ad_curr."patent_id"  = uc."patent_id"
    JOIN app_dates ad_cited ON ad_cited."patent_id" = uc."citation_id"
    WHERE ad_cited."app_date" >= DATEADD(month, -1, ad_curr."app_date")
      AND ad_cited."app_date" <  ad_curr."app_date"
    GROUP BY uc."patent_id"
),
forward_cites AS (                       -- citations ≤1 month after own app date
    SELECT
        uc."citation_id"                 AS "patent_id",
        COUNT(DISTINCT uc."patent_id")   AS "forward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN app_dates ad_curr   ON ad_curr."patent_id"   = uc."citation_id"
    JOIN app_dates ad_citing ON ad_citing."patent_id" = uc."patent_id"
    WHERE ad_citing."app_date" >  ad_curr."app_date"
      AND ad_citing."app_date" <= DATEADD(month, 1, ad_curr."app_date")
    GROUP BY uc."citation_id"
),
patents_filtered AS (                    -- gather data, require ≥1 relevant citation
    SELECT
        p."id"                                   AS "patent_id",
        p."title",
        ad."app_date",
        COALESCE(bw."backward_cnt", 0) AS "backward_cnt",
        COALESCE(fw."forward_cnt", 0)  AS "forward_cnt",
        p."abstract"
    FROM PATENTSVIEW.PATENTSVIEW.PATENT p
    JOIN app_dates    ad ON ad."patent_id" = p."id"
    JOIN cpc_patents  cp ON cp."patent_id" = p."id"
    LEFT JOIN backward_cites bw ON bw."patent_id" = p."id"
    LEFT JOIN forward_cites fw ON fw."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND (COALESCE(bw."backward_cnt",0) > 0
        OR COALESCE(fw."forward_cnt",0)  > 0)
)
SELECT
    "patent_id",
    "title",
    "app_date",
    "backward_cnt",
    "forward_cnt",
    "abstract"
FROM patents_filtered
ORDER BY "app_date" ASC NULLS LAST;