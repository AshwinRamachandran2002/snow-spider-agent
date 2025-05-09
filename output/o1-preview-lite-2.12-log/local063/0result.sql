WITH city_sales_2019 AS (
    SELECT c."cust_city", SUM(s."quantity_sold") AS "total_quantity_2019"
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE co."country_name" = 'United States of America'
      AND t."calendar_quarter_id" = 1772
      AND s."promo_id" = 999
    GROUP BY c."cust_city"
),
city_sales_2020 AS (
    SELECT c."cust_city", SUM(s."quantity_sold") AS "total_quantity_2020"
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE co."country_name" = 'United States of America'
      AND t."calendar_quarter_id" = 1776
      AND s."promo_id" = 999
    GROUP BY c."cust_city"
),
cities_increased AS (
    SELECT s2020."cust_city"
    FROM city_sales_2020 s2020
    JOIN city_sales_2019 s2019 ON s2020."cust_city" = s2019."cust_city"
    WHERE s2020."total_quantity_2020" >= s2019."total_quantity_2019" * 1.2
),
product_totals AS (
    SELECT p."prod_name", SUM(s."quantity_sold") AS "total_quantity"
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    JOIN "products" p ON s."prod_id" = p."prod_id"
    WHERE s."promo_id" = 999
      AND co."country_name" = 'United States of America'
      AND c."cust_city" IN (SELECT "cust_city" FROM cities_increased)
      AND t."calendar_quarter_id" IN (1772, 1776)
    GROUP BY p."prod_name"
),
ranked_products AS (
    SELECT "prod_name", "total_quantity", ROW_NUMBER() OVER (ORDER BY "total_quantity" DESC) AS rn
    FROM product_totals
),
total_products AS (
    SELECT COUNT(*) AS "total_products" FROM ranked_products
),
cutoff AS (
    SELECT CAST("total_products" * 0.2 AS INT) + 1 AS "cutoff_rank" FROM total_products
),
top_products AS (
    SELECT "prod_name" FROM ranked_products, cutoff WHERE rn <= cutoff."cutoff_rank"
),
total_quantity_2019 AS (
    SELECT SUM(s."quantity_sold") AS "total_quantity"
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE s."promo_id" = 999
      AND co."country_name" = 'United States of America'
      AND c."cust_city" IN (SELECT "cust_city" FROM cities_increased)
      AND t."calendar_quarter_id" = 1772
),
total_quantity_2020 AS (
    SELECT SUM(s."quantity_sold") AS "total_quantity"
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE s."promo_id" = 999
      AND co."country_name" = 'United States of America'
      AND c."cust_city" IN (SELECT "cust_city" FROM cities_increased)
      AND t."calendar_quarter_id" = 1776
)
SELECT p."prod_name" AS "Product_Name",
       ROUND(
       ((SUM(CASE WHEN t."calendar_quarter_id" = 1776 THEN s."quantity_sold" ELSE 0 END) * 1.0 / total_quantity_2020."total_quantity") -
        (SUM(CASE WHEN t."calendar_quarter_id" = 1772 THEN s."quantity_sold" ELSE 0 END) * 1.0 / total_quantity_2019."total_quantity")) * 100
       , 4) AS "Percentage_Point_Change"
FROM "sales" s
JOIN "customers" c ON s."cust_id" = c."cust_id"
JOIN "countries" co ON c."country_id" = co."country_id"
JOIN "times" t ON s."time_id" = t."time_id"
JOIN "products" p ON s."prod_id" = p."prod_id"
CROSS JOIN total_quantity_2019
CROSS JOIN total_quantity_2020
WHERE s."promo_id" = 999
  AND co."country_name" = 'United States of America'
  AND c."cust_city" IN (SELECT "cust_city" FROM cities_increased)
  AND t."calendar_quarter_id" IN (1772, 1776)
  AND p."prod_name" IN (SELECT "prod_name" FROM top_products)
GROUP BY p."prod_name", total_quantity_2019."total_quantity", total_quantity_2020."total_quantity"
ORDER BY "Percentage_Point_Change" ASC
LIMIT 1;