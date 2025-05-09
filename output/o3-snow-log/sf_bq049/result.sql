WITH clean_sales AS (
    SELECT
        "sale_dollars"                                               AS sale_dollars ,
        "date"                                                       AS order_date  ,
        UPPER(TRIM("county"))                                        AS county      ,
        SUBSTR(TRIM("zip_code"),1,5)                                 AS zip5        ,
        UPPER(TRIM("category_name"))                                 AS category_name
    FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES.SALES
    WHERE "sale_dollars" > 0
) ,

/* 1. 2022 Bourbon sales by ZIP in Dubuque County */
bourbon_2022_dubuque AS (
    SELECT
        zip5 ,
        sale_dollars
    FROM clean_sales
    WHERE county = 'DUBUQUE'
      AND category_name LIKE '%BOURBON%'
      AND YEAR(order_date) = 2022
) ,

/* 2.  Total 2022 Bourbon sales per ZIP and ranking */
ranked_zips AS (
    SELECT
        zip5 ,
        SUM(sale_dollars)                                       AS total_sales ,
        ROW_NUMBER() OVER (ORDER BY SUM(sale_dollars) DESC NULLS LAST) AS rn
    FROM bourbon_2022_dubuque
    GROUP BY zip5
) ,

/* 3.  The ZIP code that ranks third */
target_zip AS (
    SELECT zip5
    FROM ranked_zips
    WHERE rn = 3
) ,

/* 4.  Population aged 21+ in the target ZIP (2010 Census) */
population_21plus AS (
    SELECT
        "zipcode"                    AS zip5 ,
        SUM("population")            AS pop21
    FROM IOWA_LIQUOR_SALES_PLUS.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010
    WHERE "zipcode" IN (SELECT zip5 FROM target_zip)
      AND "minimum_age" >= 21
    GROUP BY "zipcode"
) ,

/* 5.  Monthly 2022 Bourbon sales in the target ZIP */
monthly_sales AS (
    SELECT
        TO_CHAR(DATE_TRUNC('month', order_date),'YYYY-MM')      AS month ,
        SUM(sale_dollars)                                       AS monthly_sales
    FROM clean_sales
    WHERE county = 'DUBUQUE'
      AND category_name LIKE '%BOURBON%'
      AND YEAR(order_date) = 2022
      AND zip5 IN (SELECT zip5 FROM target_zip)
    GROUP BY DATE_TRUNC('month', order_date)
)

/* 6.  Per-capita Bourbon sales by month (21+ population) */
SELECT
    m.month ,
    ROUND(m.monthly_sales / p.pop21 , 4)  AS per_capita_bourbon_sales
FROM monthly_sales   m
CROSS JOIN population_21plus p
ORDER BY m.month;