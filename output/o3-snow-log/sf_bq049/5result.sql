/*  Monthly per–capita Bourbon-whiskey sales in 2022  
    Dubuque County – ZIP code that ranks 3rd in 2022 Bourbon sales  */

WITH sales_2022 AS (                           -- 1. 2022 Bourbon sales in Dubuque County
    SELECT
        REGEXP_SUBSTR("zip_code" , '^[0-9]{5}')         AS "zip5" ,
        "sale_dollars"                                  AS "sale_dollars" ,
        DATE_TRUNC('month', "date")                     AS "sales_month"
    FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES.SALES
    WHERE
        "county" = 'DUBUQUE'
        AND "date" >= '2022-01-01' AND "date" < '2023-01-01'
        AND UPPER("category_name") LIKE '%BOURBON%'
),

ranked_zips AS (                            -- 2. rank ZIP codes by total 2022 Bourbon sales
    SELECT
        "zip5",
        SUM("sale_dollars")                         AS "total_sales_2022",
        DENSE_RANK() OVER (ORDER BY SUM("sale_dollars") DESC NULLS LAST)  AS "sales_rank"
    FROM sales_2022
    GROUP BY "zip5"
),

third_zip AS (                              -- 3. ZIP code that ranks 3rd
    SELECT "zip5"
    FROM ranked_zips
    WHERE "sales_rank" = 3
),

monthly_sales AS (                          -- 4. monthly sales for that ZIP code
    SELECT
        s."sales_month",
        SUM(s."sale_dollars") AS "monthly_sales_dollars"
    FROM sales_2022  s
    JOIN third_zip   z  ON s."zip5" = z."zip5"
    GROUP BY s."sales_month"
),

population_21_plus AS (                     -- 5. 21+ population (2010 Census) for that ZIP
    SELECT
        SUM("population") AS "pop_21_plus"
    FROM IOWA_LIQUOR_SALES_PLUS.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010
    WHERE
        "zipcode" = (SELECT "zip5" FROM third_zip)
        AND ( "gender" IS NULL OR "gender" = '' )
        AND "minimum_age" >= 21
)

SELECT                                         -- 6.  per–capita monthly sales
    TO_CHAR("sales_month", 'YYYY-MM')                AS "month",
    ROUND("monthly_sales_dollars" / "pop_21_plus", 4) AS "per_capita_sales_dollars"
FROM monthly_sales, population_21_plus
ORDER BY "month";