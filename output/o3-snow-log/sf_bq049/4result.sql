WITH bourbon_sales_2022 AS (
    SELECT
        SPLIT_PART("zip_code", '.', 1)                          AS "zip",
        SUM("sale_dollars")                                    AS "total_sales"
    FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" <  '2023-01-01'
      AND UPPER("county") = 'DUBUQUE'
      AND "category_name" ILIKE '%BOURBON%'
    GROUP BY SPLIT_PART("zip_code", '.', 1)
),
ranked_zips AS (
    SELECT
        "zip",
        "total_sales",
        ROW_NUMBER() OVER (ORDER BY "total_sales" DESC NULLS LAST) AS "rnk"
    FROM bourbon_sales_2022
),
selected_zip AS (
    SELECT "zip"
    FROM ranked_zips
    WHERE "rnk" = 3
),
population_21plus AS (
    SELECT
        SUM("population") AS "pop_21plus"
    FROM IOWA_LIQUOR_SALES_PLUS.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010
    WHERE "zipcode" = (SELECT "zip" FROM selected_zip)
      AND ("gender" IS NULL OR "gender" = '')
      AND "minimum_age" >= 21
)
SELECT
    TO_CHAR(DATE_TRUNC('month', s."date"), 'YYYY-MM')                AS "month",
    ROUND(SUM(s."sale_dollars") / pop."pop_21plus", 4)               AS "per_capita_bourbon_sales"
FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES.SALES s
JOIN selected_zip z
  ON SPLIT_PART(s."zip_code", '.', 1) = z."zip"
CROSS JOIN population_21plus pop
WHERE s."date" >= '2022-01-01'
  AND s."date" <  '2023-01-01'
  AND s."category_name" ILIKE '%BOURBON%'
GROUP BY
    TO_CHAR(DATE_TRUNC('month', s."date"), 'YYYY-MM'),
    pop."pop_21plus"
ORDER BY
    "month";