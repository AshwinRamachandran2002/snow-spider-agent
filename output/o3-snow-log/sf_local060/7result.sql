WITH sales_filtered AS (   -- U.S. only, Q4-2019 & Q4-2020, no-promo
    SELECT
        s."prod_id",
        s."amount_sold",
        cu."cust_city"                    AS "city",
        t."calendar_year"                 AS "year"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"      s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"      t  ON s."time_id" = t."time_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  cu ON s."cust_id" = cu."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"  co ON cu."country_id" = co."country_id"
    WHERE s."promo_id" = 999                                    -- no promotions
      AND co."country_iso_code" = 'US'                          -- United States
      AND t."calendar_quarter_number" = 4                       -- Q4
      AND t."calendar_year" IN (2019, 2020)
),                                                          
city_sales AS (            -- total city sales per year
    SELECT
        "city",
        "year",
        SUM("amount_sold") AS "city_sales"
    FROM sales_filtered
    GROUP BY "city", "year"
),                                                            
city_growth AS (           -- cities whose sales grew ≥20 %
    SELECT
        c19."city",
        c19."city_sales" AS "sales_2019",
        c20."city_sales" AS "sales_2020"
    FROM  (SELECT * FROM city_sales WHERE "year" = 2019) c19
    JOIN  (SELECT * FROM city_sales WHERE "year" = 2020) c20
          ON c19."city" = c20."city"
    WHERE c19."city_sales" > 0
      AND (c20."city_sales" - c19."city_sales") / c19."city_sales" >= 0.20
),                                                            
selected_sales AS (        -- only sales in the growing cities
    SELECT sf.*
    FROM sales_filtered sf
    JOIN city_growth cg ON sf."city" = cg."city"
),                                                            
product_totals AS (        -- total product sales (both years, selected cities)
    SELECT
        "prod_id",
        SUM("amount_sold") AS "total_sales"
    FROM selected_sales
    GROUP BY "prod_id"
),                                                            
ranked_products AS (       -- top 20 % by total sales
    SELECT
        "prod_id",
        NTILE(5) OVER (ORDER BY "total_sales" DESC) AS "tile"
    FROM product_totals
),                                                            
top_products AS (
    SELECT "prod_id"
    FROM ranked_products
    WHERE "tile" = 1                      -- keep top 20 %
),                                                            
product_year_sales AS (    -- sales per product per year (top products only)
    SELECT
        ss."prod_id",
        ss."year",
        SUM(ss."amount_sold") AS "prod_year_sales"
    FROM selected_sales ss
    JOIN top_products tp ON ss."prod_id" = tp."prod_id"
    GROUP BY ss."prod_id", ss."year"
),                                                            
year_totals AS (           -- total sales per year (all products, selected cities)
    SELECT
        "year",
        SUM("amount_sold") AS "year_total_sales"
    FROM selected_sales
    GROUP BY "year"
),                                                            
product_shares AS (        -- product share per year
    SELECT
        pys."prod_id",
        pys."year",
        ROUND(pys."prod_year_sales" / yt."year_total_sales", 4) AS "share"
    FROM product_year_sales pys
    JOIN year_totals       yt ON pys."year" = yt."year"
),                                                            
pivot_shares AS (          -- turn rows into columns
    SELECT
        "prod_id",
        MAX(CASE WHEN "year" = 2019 THEN "share" END) AS "share_2019",
        MAX(CASE WHEN "year" = 2020 THEN "share" END) AS "share_2020"
    FROM product_shares
    GROUP BY "prod_id"
)                                                              
SELECT
    ps."prod_id",
    pr."prod_name",
    COALESCE(ps."share_2019", 0)          AS "share_2019",
    COALESCE(ps."share_2020", 0)          AS "share_2020",
    ROUND(COALESCE(ps."share_2020", 0) 
        - COALESCE(ps."share_2019", 0), 4) AS "share_change"
FROM pivot_shares                     ps
JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."PRODUCTS" pr
     ON ps."prod_id" = pr."prod_id"
ORDER BY "share_change" DESC NULLS LAST;