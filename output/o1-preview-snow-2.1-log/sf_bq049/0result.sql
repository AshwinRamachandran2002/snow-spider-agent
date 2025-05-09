WITH sales_by_month AS (
    SELECT
        EXTRACT(MONTH FROM "date") AS "month",
        SUM("sale_dollars") AS "total_bourbon_sales"
    FROM
        "IOWA_LIQUOR_SALES_PLUS"."IOWA_LIQUOR_SALES"."SALES"
    WHERE
        "county" = 'DUBUQUE'
        AND "category_name" ILIKE '%Bourbon%'
        AND "date" BETWEEN '2022-01-01' AND '2022-12-31'
        AND CAST(CAST("zip_code" AS FLOAT) AS INT) = 52003
    GROUP BY
        EXTRACT(MONTH FROM "date")
),
population_over_21 AS (
    SELECT
        SUM("population") AS "population_over_21"
    FROM
        "IOWA_LIQUOR_SALES_PLUS"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010"
    WHERE
        "zipcode" = '52003'
        AND "minimum_age" >= 21
)
SELECT
    '52003' AS "Zip_Code",
    TO_CHAR(DATE_FROM_PARTS(2022, "month", 1), 'MON-YYYY') AS "Month",
    ROUND("total_bourbon_sales" / "population_over_21", 4) AS "Per_Capita_Sales"
FROM
    sales_by_month,
    population_over_21
ORDER BY
    "month";