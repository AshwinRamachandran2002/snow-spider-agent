WITH "APP" AS (     /* earliest valid U.S. application date for every patent */
    SELECT
        "patent_id",
        MIN("parsed_date") AS "app_date"
    FROM (
        SELECT
            "patent_id",
            TRY_TO_DATE("date",'YYYY-MM-DD') AS "parsed_date"
        FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
        WHERE "country" = 'US'
    )
    WHERE "parsed_date" IS NOT NULL
    GROUP BY "patent_id"
),

"BACKWARD_1YR" AS ( /* backward citations filed ≤1 year before own app date */
    SELECT
        uc."patent_id",
        COUNT(*) AS "backward_1yr_ct"
    FROM (
        SELECT
            "patent_id",
            "date",
            TRY_TO_DATE("date",'YYYY-MM-DD') AS "cite_date"
        FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION
    ) uc
    JOIN "APP" a
          ON a."patent_id" = uc."patent_id"
    WHERE uc."cite_date" IS NOT NULL
      AND uc."cite_date" BETWEEN DATEADD(year,-1,a."app_date") AND a."app_date"
    GROUP BY uc."patent_id"
),

"FORWARD_COUNTS" AS ( /* forward citations received within 1 & 3 yrs */
    SELECT
        uc."citation_id" AS "patent_id",
        SUM( CASE WHEN p_app."app_date"
                        BETWEEN c_app."app_date"
                            AND DATEADD(year,1,c_app."app_date")
                  THEN 1 END ) AS "forward_1yr_ct",
        SUM( CASE WHEN p_app."app_date"
                        BETWEEN c_app."app_date"
                            AND DATEADD(year,3,c_app."app_date")
                  THEN 1 END ) AS "forward_3yr_ct"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN "APP" c_app ON c_app."patent_id" = uc."citation_id"   /* cited (focal) */
    JOIN "APP" p_app ON p_app."patent_id" = uc."patent_id"     /* citing */
    GROUP BY uc."citation_id"
),

"CPC_FILTER" AS (   /* restrict to selected CPC groups */
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "group_id" IN ('G06F','C12Y')
)

SELECT
    a."patent_id",
    b."backward_1yr_ct"  AS "backward_citations_within_1yr",
    f."forward_3yr_ct"   AS "forward_citations_within_3yrs"
FROM "APP"            a
JOIN "BACKWARD_1YR"   b ON b."patent_id" = a."patent_id"
JOIN "FORWARD_COUNTS" f ON f."patent_id" = a."patent_id"
JOIN "CPC_FILTER"     c ON c."patent_id" = a."patent_id"
WHERE f."forward_1yr_ct" > 0        /* at least one forward citation within 1 yr */
ORDER BY b."backward_1yr_ct" DESC NULLS LAST, a."patent_id"
LIMIT 1;