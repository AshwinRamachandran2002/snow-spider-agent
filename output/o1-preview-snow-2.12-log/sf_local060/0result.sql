WITH cities_with_20pc_increase AS (
    SELECT c."cust_city"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" cnt ON c."country_id" = cnt."country_id"
    WHERE t."calendar_quarter_number" = 4
      AND t."calendar_year" IN (2019, 2020)
      AND s."promo_id" = 999
      AND cnt."country_name" = 'United States of America'
    GROUP BY c."cust_city"
    HAVING SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" ELSE 0 END) > 0
       AND ((SUM(CASE WHEN t."calendar_year" = 2020 THEN s."amount_sold" ELSE 0 END) -
             SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" ELSE 0 END)) /
             NULLIF(SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" ELSE 0 END),0) * 100) >= 20
),
product_sales AS (
  SELECT s."prod_id",
         SUM(s."amount_sold") AS "total_sales"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  WHERE t."calendar_quarter_number" = 4
    AND t."calendar_year" IN (2019, 2020)
    AND s."promo_id" = 999
    AND c."cust_city" IN (SELECT "cust_city" FROM cities_with_20pc_increase)
  GROUP BY s."prod_id"
),
product_sales_ranked AS (
  SELECT p.*,
         RANK() OVER (ORDER BY "total_sales" DESC) AS "sales_rank"
  FROM product_sales p
),
product_counts AS (
  SELECT COUNT(*) AS total_products, CEIL(COUNT(*) * 0.2) AS top_20_percent_count
  FROM product_sales
),
top_products AS (
  SELECT psr."prod_id"
  FROM product_sales_ranked psr
  CROSS JOIN product_counts pc
  WHERE psr."sales_rank" <= pc.top_20_percent_count
),
product_sales_by_year AS (
  SELECT s."prod_id",
         SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" ELSE 0 END) AS "sales_2019",
         SUM(CASE WHEN t."calendar_year" = 2020 THEN s."amount_sold" ELSE 0 END) AS "sales_2020"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  WHERE t."calendar_quarter_number" = 4
    AND t."calendar_year" IN (2019, 2020)
    AND s."promo_id" = 999
    AND c."cust_city" IN (SELECT "cust_city" FROM cities_with_20pc_increase)
    AND s."prod_id" IN (SELECT "prod_id" FROM top_products)
  GROUP BY s."prod_id"
),
total_sales_per_year AS (
  SELECT t."calendar_year" AS "year",
         SUM(s."amount_sold") AS "total_sales"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
  WHERE t."calendar_quarter_number" = 4
    AND t."calendar_year" IN (2019,2020)
    AND s."promo_id" = 999
    AND c."cust_city" IN (SELECT "cust_city" FROM cities_with_20pc_increase)
  GROUP BY t."calendar_year"
)
SELECT ps."prod_id" AS "Product_ID",
       pr."prod_name" AS "Product_Name",
       ROUND((ps."sales_2019" / (SELECT "total_sales" FROM total_sales_per_year WHERE "year" = 2019)) * 100, 4) AS "Share_Q4_2019",
       ROUND((ps."sales_2020" / (SELECT "total_sales" FROM total_sales_per_year WHERE "year" = 2020)) * 100, 4) AS "Share_Q4_2020",
       ROUND(((ps."sales_2020" / (SELECT "total_sales" FROM total_sales_per_year WHERE "year" = 2020)) -
        (ps."sales_2019" / (SELECT "total_sales" FROM total_sales_per_year WHERE "year" = 2019))) * 100, 4) AS "Share_Change"
FROM product_sales_by_year ps
JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PRODUCTS" pr ON ps."prod_id" = pr."prod_id"
ORDER BY "Share_Change" DESC NULLS LAST