WITH total_products AS (
    SELECT COUNT(DISTINCT "prod_id") AS total_products FROM "sales"
),
top_products AS (
    SELECT "prod_id"
    FROM "sales"
    GROUP BY "prod_id"
    ORDER BY SUM("quantity_sold") DESC
    LIMIT (
        SELECT CAST(total_products.total_products * 0.2 AS INTEGER)
        FROM total_products
    )
),
total_sales_2019 AS (
    SELECT SUM(s."quantity_sold") AS total_quantity_sold
    FROM "sales" AS s
    JOIN "customers" AS c ON s."cust_id" = c."cust_id"
    JOIN "countries" AS co ON c."country_id" = co."country_id"
    JOIN "times" AS t ON s."time_id" = t."time_id"
    WHERE co."country_name" = 'United States of America'
      AND t."calendar_year" = 2019
      AND t."calendar_quarter_number" = 4
      AND s."promo_id" = 999
),
total_sales_2020 AS (
    SELECT SUM(s."quantity_sold") AS total_quantity_sold
    FROM "sales" AS s
    JOIN "customers" AS c ON s."cust_id" = c."cust_id"
    JOIN "countries" AS co ON c."country_id" = co."country_id"
    JOIN "times" AS t ON s."time_id" = t."time_id"
    WHERE co."country_name" = 'United States of America'
      AND t."calendar_year" = 2020
      AND t."calendar_quarter_number" = 4
      AND s."promo_id" = 999
),
product_sales_2019 AS (
    SELECT s."prod_id", SUM(s."quantity_sold") AS product_quantity_sold
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE co."country_name" = 'United States of America'
        AND t."calendar_year" = 2019
        AND t."calendar_quarter_number" = 4
        AND s."promo_id" = 999
        AND s."prod_id" IN (SELECT "prod_id" FROM top_products)
    GROUP BY s."prod_id"
),
product_sales_2020 AS (
    SELECT s."prod_id", SUM(s."quantity_sold") AS product_quantity_sold
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE co."country_name" = 'United States of America'
        AND t."calendar_year" = 2020
        AND t."calendar_quarter_number" = 4
        AND s."promo_id" = 999
        AND s."prod_id" IN (SELECT "prod_id" FROM top_products)
    GROUP BY s."prod_id"
),
sales_share_changes AS (
    SELECT
        p."prod_id",
        p."prod_name",
        COALESCE(ps2019.product_quantity_sold, 0.0) / (SELECT total_quantity_sold FROM total_sales_2019) AS sales_share_2019,
        COALESCE(ps2020.product_quantity_sold, 0.0) / (SELECT total_quantity_sold FROM total_sales_2020) AS sales_share_2020,
        (
            COALESCE(ps2020.product_quantity_sold, 0.0) / (SELECT total_quantity_sold FROM total_sales_2020)
            -
            COALESCE(ps2019.product_quantity_sold, 0.0) / (SELECT total_quantity_sold FROM total_sales_2019)
        ) AS sales_share_change
    FROM "products" p
    LEFT JOIN product_sales_2019 ps2019 ON p."prod_id" = ps2019."prod_id"
    LEFT JOIN product_sales_2020 ps2020 ON p."prod_id" = ps2020."prod_id"
    WHERE p."prod_id" IN (SELECT "prod_id" FROM top_products)
)
SELECT
    "prod_name" AS "Product_Name"
FROM sales_share_changes
ORDER BY ABS(sales_share_change) ASC
LIMIT 1;