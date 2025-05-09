WITH city_sales AS (
    SELECT c."cust_city", t."calendar_year", SUM(s."amount_sold") AS total_sales
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE s."promo_id" = 999
      AND co."country_name" = 'United States of America'
      AND t."calendar_year" IN (2019, 2020)
      AND t."calendar_quarter_number" = 4
    GROUP BY c."cust_city", t."calendar_year"
),
cities_with_increase AS (
    SELECT s2019."cust_city"
    FROM city_sales s2019
    JOIN city_sales s2020 ON s2019."cust_city" = s2020."cust_city"
    WHERE s2019."calendar_year" = 2019
      AND s2020."calendar_year" = 2020
      AND s2020.total_sales >= s2019.total_sales * 1.2
),
product_sales AS (
    SELECT p."prod_name", SUM(s."amount_sold") AS total_sales
    FROM "sales" s
    JOIN "products" p ON s."prod_id" = p."prod_id"
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE s."promo_id" = 999
      AND co."country_name" = 'United States of America'
      AND c."cust_city" IN (SELECT "cust_city" FROM cities_with_increase)
      AND t."calendar_year" IN (2019, 2020)
      AND t."calendar_quarter_number" = 4
    GROUP BY p."prod_name"
    ORDER BY total_sales DESC
),
top_products AS (
    SELECT "prod_name"
    FROM product_sales
    LIMIT (SELECT ROUND(0.2 * COUNT(*)) FROM product_sales)
),
product_shares AS (
    SELECT p."prod_name", t."calendar_year", SUM(s."amount_sold") AS product_sales,
           SUM(s."amount_sold") / (
             SELECT SUM(s_total."amount_sold")
             FROM "sales" s_total
             JOIN "customers" c_total ON s_total."cust_id" = c_total."cust_id"
             JOIN "countries" co_total ON c_total."country_id" = co_total."country_id"
             JOIN "times" t_total ON s_total."time_id" = t_total."time_id"
             WHERE s_total."promo_id" = 999
               AND co_total."country_name" = 'United States of America'
               AND c_total."cust_city" IN (SELECT "cust_city" FROM cities_with_increase)
               AND t_total."calendar_year" = t."calendar_year"
               AND t_total."calendar_quarter_number" = 4
          ) AS sales_share
    FROM "sales" s
    JOIN "products" p ON s."prod_id" = p."prod_id"
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE s."promo_id" = 999
      AND co."country_name" = 'United States of America'
      AND c."cust_city" IN (SELECT "cust_city" FROM cities_with_increase)
      AND t."calendar_year" IN (2019, 2020)
      AND t."calendar_quarter_number" = 4
      AND p."prod_name" IN (SELECT "prod_name" FROM top_products)
    GROUP BY p."prod_name", t."calendar_year"
)
SELECT ps2020."prod_name" AS Product_Name,
       ROUND(ps2019.sales_share, 4) AS Share_2019,
       ROUND(ps2020.sales_share, 4) AS Share_2020,
       ROUND(ps2020.sales_share - ps2019.sales_share, 4) AS Share_Change
FROM product_shares ps2019
JOIN product_shares ps2020 ON ps2019."prod_name" = ps2020."prod_name"
WHERE ps2019."calendar_year" = 2019
  AND ps2020."calendar_year" = 2020
ORDER BY Share_Change DESC;