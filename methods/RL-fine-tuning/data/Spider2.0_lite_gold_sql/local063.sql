WITH city_sales_2019 AS (
    SELECT cu."cust_city" AS city,
           SUM(s."quantity_sold") AS total_quantity
    FROM "sales" AS s
    JOIN "customers" AS cu ON s."cust_id" = cu."cust_id"
    JOIN "countries" AS co ON cu."country_id" = co."country_id"
    JOIN "times" AS t ON s."time_id" = t."time_id"
    WHERE co."country_name" = 'United States of America'
      AND s."promo_id" = 999
      AND t."calendar_quarter_id" = 1772
    GROUP BY cu."cust_city"
),
city_sales_2020 AS (
    SELECT cu."cust_city" AS city,
           SUM(s."quantity_sold") AS total_quantity
    FROM "sales" AS s
    JOIN "customers" AS cu ON s."cust_id" = cu."cust_id"
    JOIN "countries" AS co ON cu."country_id" = co."country_id"
    JOIN "times" AS t ON s."time_id" = t."time_id"
    WHERE co."country_name" = 'United States of America'
      AND s."promo_id" = 999
      AND t."calendar_quarter_id" = 1776
    GROUP BY cu."cust_city"
),
city_growth AS (
    SELECT c19.city
    FROM city_sales_2019 c19
    JOIN city_sales_2020 c20 ON c19.city = c20.city
    WHERE (c20.total_quantity - c19.total_quantity) * 1.0 / c19.total_quantity >= 0.20
),
product_sales AS (
    SELECT
        p."prod_name" AS product,
        t."calendar_quarter_id" AS quarter,
        SUM(s."quantity_sold") AS product_quantity
    FROM "sales" AS s
    JOIN "products" AS p ON s."prod_id" = p."prod_id"
    JOIN "customers" AS cu ON s."cust_id" = cu."cust_id"
    JOIN "countries" AS co ON cu."country_id" = co."country_id"
    JOIN "times" AS t ON s."time_id" = t."time_id"
    WHERE co."country_name" = 'United States of America'
      AND s."promo_id" = 999
      AND t."calendar_quarter_id" IN (1772, 1776)
      AND cu."cust_city" IN (SELECT city FROM city_growth)
    GROUP BY p."prod_name", t."calendar_quarter_id"
),
total_sales_per_quarter AS (
    SELECT
        t."calendar_quarter_id" AS quarter,
        SUM(s."quantity_sold") AS total_quantity
    FROM "sales" AS s
    JOIN "customers" AS cu ON s."cust_id" = cu."cust_id"
    JOIN "countries" AS co ON cu."country_id" = co."country_id"
    JOIN "times" AS t ON s."time_id" = t."time_id"
    WHERE co."country_name" = 'United States of America'
      AND s."promo_id" = 999
      AND t."calendar_quarter_id" IN (1772, 1776)
      AND cu."cust_city" IN (SELECT city FROM city_growth)
    GROUP BY t."calendar_quarter_id"
),
product_share AS (
    SELECT
        ps.product,
        ps.quarter,
        ps.product_quantity,
        ts.total_quantity,
        ps.product_quantity * 1.0 / ts.total_quantity AS share
    FROM product_sales ps
    JOIN total_sales_per_quarter ts ON ps.quarter = ts.quarter
),
product_share_change AS (
    SELECT
        ps1.product,
        ps1.share AS share_2019,
        ps2.share AS share_2020,
        (ps2.share - ps1.share) * 100.0 AS share_change
    FROM product_share ps1
    JOIN product_share ps2 ON ps1.product = ps2.product
    WHERE ps1.product = ps2.product
      AND ps1.quarter = 1772
      AND ps2.quarter = 1776
),
product_total_sales AS (
    SELECT
        ps.product,
        SUM(ps.product_quantity) AS total_product_quantity
    FROM product_sales ps
    GROUP BY ps.product
),
top_products AS (
    SELECT product
    FROM (
        SELECT
            product,
            total_product_quantity,
            NTILE(5) OVER (ORDER BY total_product_quantity DESC) AS quintile
        FROM product_total_sales
    )
    WHERE quintile = 1
)
SELECT
    psc.product AS Product_Name,
    ROUND(psc.share_change, 4) AS Percentage_Point_Change
FROM product_share_change psc
WHERE psc.product IN (SELECT product FROM top_products)
ORDER BY ABS(psc.share_change)
LIMIT 1;