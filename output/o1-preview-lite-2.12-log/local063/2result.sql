WITH total_sales_per_product AS (
    SELECT s."prod_id", SUM(s."amount_sold") AS total_sales
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    WHERE co."country_iso_code" = 'US' AND s."promo_id" = 999
    GROUP BY s."prod_id"
),
top_products AS (
    SELECT "prod_id"
    FROM total_sales_per_product
    ORDER BY total_sales DESC
    LIMIT (
        SELECT CAST(COUNT(*) * 0.2 AS INTEGER)
        FROM total_sales_per_product
    )
),
sales_2019 AS (
    SELECT s."prod_id", SUM(s."amount_sold") AS total_sales
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE co."country_iso_code" = 'US'
      AND s."promo_id" = 999
      AND t."calendar_year" = 2019
      AND t."calendar_quarter_number" = 4
    GROUP BY s."prod_id"
),
total_sales_2019 AS (
    SELECT SUM(total_sales) AS total_sales FROM sales_2019
),
sales_share_2019 AS (
    SELECT s."prod_id", s.total_sales / total_sales_2019.total_sales AS sales_share
    FROM sales_2019 s, total_sales_2019
),
sales_2020 AS (
    SELECT s."prod_id", SUM(s."amount_sold") AS total_sales
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE co."country_iso_code" = 'US'
      AND s."promo_id" = 999
      AND t."calendar_year" = 2020
      AND t."calendar_quarter_number" = 4
    GROUP BY s."prod_id"
),
total_sales_2020 AS (
    SELECT SUM(total_sales) AS total_sales FROM sales_2020
),
sales_share_2020 AS (
    SELECT s."prod_id", s.total_sales / total_sales_2020.total_sales AS sales_share
    FROM sales_2020 s, total_sales_2020
)
SELECT p."prod_name" AS Product_Name, ROUND(ABS(s2020.sales_share - s2019.sales_share), 4) AS Share_Change
FROM top_products tp
JOIN sales_share_2019 s2019 ON tp."prod_id" = s2019."prod_id"
JOIN sales_share_2020 s2020 ON tp."prod_id" = s2020."prod_id"
JOIN "products" p ON tp."prod_id" = p."prod_id"
ORDER BY Share_Change ASC
LIMIT 1;