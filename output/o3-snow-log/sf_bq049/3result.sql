WITH bourbon_sales AS (   -- all 2022 Bourbon sales in Dubuque Co., summed by month & ZIP
    SELECT
        LPAD(REGEXP_REPLACE("zip_code", '\\.0$' , ''), 5, '0')      AS "zipcode",
        DATE_TRUNC('month', "date")                                 AS "sale_month",
        SUM("sale_dollars")                                         AS "monthly_sales"
    FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" <  '2023-01-01'
      AND "county" = 'DUBUQUE'
      AND "category_name" = 'STRAIGHT BOURBON WHISKIES'
    GROUP BY 1, 2
),
zip_totals AS (           -- total-year sales per ZIP to find the 3rd-highest
    SELECT
        "zipcode",
        SUM("monthly_sales") AS "total_sales_2022"
    FROM bourbon_sales
    GROUP BY "zipcode"
),
ranked_zips AS (
    SELECT
        "zipcode",
        RANK() OVER (ORDER BY "total_sales_2022" DESC NULLS LAST) AS "rk"
    FROM zip_totals
),
third_zip AS (            -- ZIP code that ranks 3rd
    SELECT "zipcode"
    FROM ranked_zips
    WHERE "rk" = 3
),
population_21plus AS (    -- 21-and-over population by ZIP (2010 Census)
    SELECT
        "zipcode",
        SUM("population") AS "pop_21plus"
    FROM IOWA_LIQUOR_SALES_PLUS.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010
    WHERE "minimum_age" >= 21
      AND "gender" IN ('male', 'female')
    GROUP BY "zipcode"
)
SELECT
    TO_CHAR(bs."sale_month", 'YYYY-MM')                         AS "month",
    ROUND(bs."monthly_sales" / p."pop_21plus", 4)               AS "per_capita_sales"
FROM bourbon_sales      bs
JOIN third_zip          tz  ON bs."zipcode" = tz."zipcode"
JOIN population_21plus  p   ON p."zipcode"  = tz."zipcode"
ORDER BY bs."sale_month";