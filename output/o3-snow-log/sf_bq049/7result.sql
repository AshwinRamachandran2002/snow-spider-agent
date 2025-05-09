WITH bourbon_sales_2022 AS (          -- Monthly 2022 Bourbon-whiskey sales in Dubuque County
    SELECT
        SPLIT_PART("zip_code",'.',1)                     AS "zipcode",
        DATE_TRUNC('month',"date")                       AS "month",
        SUM("sale_dollars")                              AS "total_sales_usd"
    FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES."SALES"
    WHERE UPPER("county") = 'DUBUQUE'                   -- Dubuque County only
      AND "date" >= '2022-01-01'
      AND "date" <  '2023-01-01'
      AND "category_name" ILIKE '%BOURBON%'             -- any Bourbon-whiskey category
    GROUP BY SPLIT_PART("zip_code",'.',1), DATE_TRUNC('month',"date")
),

zip_year_sales AS (              -- 2022 total Bourbon sales by ZIP to obtain the ranking
    SELECT
        "zipcode",
        SUM("total_sales_usd") AS "year_sales_usd"
    FROM bourbon_sales_2022
    GROUP BY "zipcode"
),

third_place_zip AS (             -- ZIP code ranked 3rd in total 2022 Bourbon sales
    SELECT "zipcode"
    FROM (
        SELECT
            "zipcode",
            "year_sales_usd",
            DENSE_RANK() OVER (ORDER BY "year_sales_usd" DESC NULLS LAST) AS "rk"
        FROM zip_year_sales
    )
    WHERE "rk" = 3
    LIMIT 1                                           -- just one ZIP
),

pop_21_plus AS (                 -- population aged 21+ per ZIP (2010 Census)
    SELECT
        "zipcode",
        SUM("population") AS "pop_21_plus"
    FROM IOWA_LIQUOR_SALES_PLUS.CENSUS_BUREAU_USA."POPULATION_BY_ZIP_2010"
    WHERE ("gender" IS NULL OR "gender" = '')         -- total population rows only
      AND "minimum_age" >= 21                         -- age 21 and older
    GROUP BY "zipcode"
),

monthly_per_capita AS (          -- Combine sales and population for the selected ZIP
    SELECT
        s."month",
        s."total_sales_usd" / NULLIF(p."pop_21_plus",0) AS "per_capita_sales_usd"
    FROM bourbon_sales_2022  s
    JOIN third_place_zip     z ON s."zipcode" = z."zipcode"
    LEFT JOIN pop_21_plus    p ON s."zipcode" = p."zipcode"
)

SELECT
    TO_CHAR("month",'YYYY-MM')           AS "MONTH",
    ROUND("per_capita_sales_usd",4)      AS "PER_CAPITA_BOURBON_SALES_USD"
FROM monthly_per_capita
ORDER BY "month";