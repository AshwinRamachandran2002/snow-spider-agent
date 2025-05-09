WITH "CLEANED_SALES" AS (   -- 1. Bourbon-whiskey sales in Dubuque Co. during 2022
    SELECT
        DATE_TRUNC('month', "date")                                AS "month",
        LPAD(REPLACE("zip_code", '.0', ''), 5, '0')                AS "zipcode",
        "sale_dollars"
    FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" <  '2023-01-01'
      AND "county" ILIKE 'DUBUQUE%'              -- Dubuque County (case-insensitive)
      AND "category_name" ILIKE '%BOURBON%'       -- all Bourbon whiskey categories
),
"SALES_2022" AS (           -- 2. Aggregate by month & ZIP
    SELECT
        "month",
        "zipcode",
        SUM("sale_dollars") AS "sales"
    FROM "CLEANED_SALES"
    GROUP BY "month", "zipcode"
),
"ZIP_RANK" AS (             -- 3. Rank ZIP codes by total 2022 Bourbon sales
    SELECT
        "zipcode",
        SUM("sales") AS "total_sales",
        DENSE_RANK() OVER (ORDER BY SUM("sales") DESC NULLS LAST) AS "rk"
    FROM "SALES_2022"
    GROUP BY "zipcode"
),
"TARGET_ZIP" AS (           -- 4. ZIP code that ranks third
    SELECT "zipcode"
    FROM "ZIP_RANK"
    WHERE "rk" = 3
),
"POP_21_PLUS" AS (          -- 5. 2010 population aged 21+ for that ZIP
    SELECT
        "zipcode",
        SUM("population") AS "pop_21_plus"
    FROM IOWA_LIQUOR_SALES_PLUS.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010
    WHERE "zipcode" IN (SELECT "zipcode" FROM "TARGET_ZIP")
      AND ( "maximum_age" >= 21 OR "maximum_age" IS NULL )        -- include 21+
      AND ( "gender" IS NULL OR "gender" = '' )
    GROUP BY "zipcode"
),
"PER_CAPITA" AS (           -- 6. Compute monthly per-capita sales
    SELECT
        s."month",
        SUM(s."sales")                             AS "monthly_sales",
        p."pop_21_plus",
        SUM(s."sales") / p."pop_21_plus"           AS "per_capita_sales"
    FROM "SALES_2022" s
    JOIN "TARGET_ZIP" t ON s."zipcode" = t."zipcode"
    JOIN "POP_21_PLUS" p ON s."zipcode" = p."zipcode"
    GROUP BY s."month", p."pop_21_plus"
)
SELECT
    TO_CHAR("month", 'YYYY-MM')  AS "month",
    ROUND("per_capita_sales", 4) AS "per_capita_sales"
FROM "PER_CAPITA"
ORDER BY "month";