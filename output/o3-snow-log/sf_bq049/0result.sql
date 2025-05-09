/* -----------------------------------------------------------
   Monthly per–capita  (age 21+) Bourbon-Whiskey sales, 2022
   Dubuque County – ZIP code that ranks 3rd in 2022 Bourbon $
-------------------------------------------------------------*/
WITH sales_filtered AS (                       -- 1. 2022 Bourbon sales in Dubuque County
    SELECT
        REGEXP_SUBSTR("zip_code", '[0-9]{5}')           AS "zipcode",
        "date",
        "sale_dollars"
    FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES.SALES
    WHERE TRIM(UPPER("county")) = 'DUBUQUE'
      AND "date" >= '2022-01-01' AND "date" < '2023-01-01'
      AND UPPER("category_name") LIKE '%BOURBON%'
      AND REGEXP_SUBSTR("zip_code", '[0-9]{5}') IS NOT NULL
),
total_sales_by_zip AS (                       -- 2. Total 2022 Bourbon $ by ZIP
    SELECT
        "zipcode",
        SUM("sale_dollars") AS "total_sales_dollars"
    FROM sales_filtered
    GROUP BY "zipcode"
),
third_zip AS (                                -- 3. ZIP that ranks 3rd
    SELECT "zipcode"
    FROM (
        SELECT
            "zipcode",
            ROW_NUMBER() OVER (ORDER BY "total_sales_dollars" DESC NULLS LAST) AS "rn"
        FROM total_sales_by_zip
    )
    WHERE "rn" = 3
),
pop_totals AS (                               -- 4a. 2010 TOTAL population per ZIP
    SELECT
        "zipcode",
        SUM("population") AS "pop_total"
    FROM IOWA_LIQUOR_SALES_PLUS.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010
    WHERE ("gender" IS NULL OR "gender" = '')            -- overall (not M/F split)
      AND "minimum_age" IS NULL                           -- the TOTAL row is flagged by NULL ages
      AND "maximum_age" IS NULL
      AND "zipcode" IN (SELECT "zipcode" FROM third_zip)
    GROUP BY "zipcode"
),
pop_under21 AS (                              -- 4b. population younger than 21
    SELECT
        "zipcode",
        SUM("population") AS "pop_under21"
    FROM IOWA_LIQUOR_SALES_PLUS.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010
    WHERE ("gender" IS NULL OR "gender" = '')
      AND "maximum_age" < 21                               -- upper bound < 21 ⇒ age < 21
      AND "zipcode" IN (SELECT "zipcode" FROM third_zip)
    GROUP BY "zipcode"
),
population_21plus AS (                        -- 4c. population age 21+
    SELECT
        t."zipcode",
        (t."pop_total" - COALESCE(u."pop_under21",0)) AS "population_21plus"
    FROM pop_totals t
    LEFT JOIN pop_under21 u
           ON t."zipcode" = u."zipcode"
),
monthly_sales AS (                            -- 5. Monthly Bourbon $ for that ZIP
    SELECT
        DATE_TRUNC('month', "date") AS "month",
        SUM("sale_dollars")        AS "monthly_sales_dollars"
    FROM sales_filtered
    WHERE "zipcode" IN (SELECT "zipcode" FROM third_zip)
    GROUP BY DATE_TRUNC('month', "date")
)

SELECT
    TO_CHAR(ms."month", 'YYYY-MM')                                       AS "month",
    ms."monthly_sales_dollars",
    p."population_21plus",
    ROUND(ms."monthly_sales_dollars" / NULLIF(p."population_21plus",0), 4) AS "monthly_per_capita_sales"
FROM monthly_sales      ms
CROSS JOIN population_21plus p           -- only one ZIP, so CROSS JOIN is fine
ORDER BY ms."month";