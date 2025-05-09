WITH app AS (
    SELECT
        "patent_id",
        TRY_TO_DATE("date") AS app_date
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE TRY_TO_DATE("date") IS NOT NULL
),
cpc_filter AS (
    SELECT DISTINCT
        "patent_id",
        "group_id" AS cpc_category
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "group_id" IN ('G06F','C12Q')
),
bwd AS (
    SELECT
        a."patent_id",
        COUNT(*) AS backward_1yr
    FROM app a
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
      ON uc."patent_id" = a."patent_id"
    WHERE TRY_TO_DATE(uc."date")
          BETWEEN DATEADD(year,-1,a.app_date) AND a.app_date
    GROUP BY a."patent_id"
),
fwd1 AS (
    SELECT
        a."patent_id",
        COUNT(*) AS forward_1yr
    FROM app a
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
      ON uc."citation_id" = a."patent_id"
    WHERE TRY_TO_DATE(uc."date")
          BETWEEN a.app_date AND DATEADD(year,1,a.app_date)
    GROUP BY a."patent_id"
),
fwd3 AS (
    SELECT
        a."patent_id",
        COUNT(*) AS forward_3yr
    FROM app a
    JOIN PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
      ON uc."citation_id" = a."patent_id"
    WHERE TRY_TO_DATE(uc."date")
          BETWEEN a.app_date AND DATEADD(year,3,a.app_date)
    GROUP BY a."patent_id"
),
combined AS (
    SELECT
        b."patent_id",
        MIN(cf.cpc_category) AS cpc_category,
        b.backward_1yr,
        f1.forward_1yr,
        f3.forward_3yr,
        a.app_date
    FROM bwd b
    JOIN fwd1 f1 ON f1."patent_id" = b."patent_id"
    JOIN fwd3 f3 ON f3."patent_id" = b."patent_id"
    JOIN app a ON a."patent_id" = b."patent_id"
    JOIN cpc_filter cf ON cf."patent_id" = b."patent_id"
    GROUP BY b."patent_id", b.backward_1yr,
             f1.forward_1yr, f3.forward_3yr, a.app_date
    HAVING b.backward_1yr > 0
       AND f1.forward_1yr > 0
)
SELECT
    "patent_id" AS patent_number,
    TO_CHAR(app_date,'YYYY-MM-DD') AS application_date,
    cpc_category,
    backward_1yr AS backward_citations_within_1yr,
    forward_1yr AS forward_citations_within_1yr,
    forward_3yr AS forward_citations_within_3yrs
FROM combined
ORDER BY backward_1yr DESC NULLS LAST, patent_number
LIMIT 1;