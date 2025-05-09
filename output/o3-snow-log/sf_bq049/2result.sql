WITH sales_2022 AS (      -- 2022 Bourbon sales for stores in Dubuque County
    SELECT
        REGEXP_SUBSTR("zip_code", '^[0-9]{5}')              AS zip5,        -- clean 5-digit ZIP
        "sale_dollars",
        "date"
    FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'                     -- entire year 2022
      AND "date" <  '2023-01-01'
      AND "county" ILIKE 'DUBUQUE%'                  -- Dubuque County only
      AND "category_name" ILIKE '%BOURBON%'          -- Bourbon whiskey categories
      AND "sale_dollars" > 0                         -- keep positive sales
      AND REGEXP_SUBSTR("zip_code", '^[0-9]{5}') IS NOT NULL
),                   
ranked_zips AS (       -- total 2022 Bourbon sales by ZIP code
    SELECT
        zip5,
        SUM("sale_dollars") AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM("sale_dollars") DESC NULLS LAST) AS sales_rank
    FROM sales_2022
    GROUP BY zip5
),                   
third_zip AS (        -- ZIP code that ranks third
    SELECT zip5
    FROM ranked_zips
    WHERE sales_rank = 3
),                   
monthly_sales AS (    -- monthly Bourbon sales for that ZIP
    SELECT
        DATE_TRUNC('month', "date") AS month_start,
        SUM("sale_dollars")         AS monthly_sales,
        zip5
    FROM sales_2022
    WHERE zip5 IN (SELECT zip5 FROM third_zip)
    GROUP BY DATE_TRUNC('month', "date"), zip5
),                   
population_21plus AS (  -- population aged 21+ (2010 Census)
    SELECT
        "zipcode"                     AS zip5,
        SUM("population")             AS population_21_plus
    FROM IOWA_LIQUOR_SALES_PLUS.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010
    WHERE "minimum_age" >= 21
    GROUP BY "zipcode"
)                   
SELECT
    TO_CHAR(month_start, 'YYYY-MM')                          AS month,
    ROUND(monthly_sales / population_21_plus, 4)             AS per_capita_bourbon_sales
FROM monthly_sales
JOIN population_21plus USING (zip5)
ORDER BY month;