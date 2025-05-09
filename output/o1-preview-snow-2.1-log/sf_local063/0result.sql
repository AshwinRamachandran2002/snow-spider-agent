WITH total_sales_per_product AS (
    SELECT s."prod_id", SUM(s."amount_sold") AS "total_sales"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES s
    GROUP BY s."prod_id"
),
ranked_products AS (
    SELECT "prod_id", "total_sales",
           NTILE(5) OVER (ORDER BY "total_sales" DESC NULLS LAST) AS "sales_ntile"
    FROM total_sales_per_product
),
top_20_percent_products AS (
    SELECT "prod_id"
    FROM ranked_products
    WHERE "sales_ntile" = 1
),
sales_2019 AS (
    SELECT s."prod_id", SUM(s."amount_sold") AS "total_sales_2019"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES t ON s."time_id" = t."time_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS c ON s."cust_id" = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES cn ON c."country_id" = cn."country_id"
    WHERE t."calendar_year" = 2019
      AND t."calendar_quarter_number" = 4
      AND s."promo_id" = 999
      AND cn."country_name" = 'United States of America'
    GROUP BY s."prod_id"
),
total_sales_2019 AS (
    SELECT SUM(s."amount_sold") AS "overall_total_2019"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES t ON s."time_id" = t."time_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS c ON s."cust_id" = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES cn ON c."country_id" = cn."country_id"
    WHERE t."calendar_year" = 2019
      AND t."calendar_quarter_number" = 4
      AND s."promo_id" = 999
      AND cn."country_name" = 'United States of America'
),
sales_2020 AS (
    SELECT s."prod_id", SUM(s."amount_sold") AS "total_sales_2020"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES t ON s."time_id" = t."time_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS c ON s."cust_id" = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES cn ON c."country_id" = cn."country_id"
    WHERE t."calendar_year" = 2020
      AND t."calendar_quarter_number" = 4
      AND s."promo_id" = 999
      AND cn."country_name" = 'United States of America'
    GROUP BY s."prod_id"
),
total_sales_2020 AS (
    SELECT SUM(s."amount_sold") AS "overall_total_2020"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES t ON s."time_id" = t."time_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS c ON s."cust_id" = c."cust_id"
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES cn ON c."country_id" = cn."country_id"
    WHERE t."calendar_year" = 2020
      AND t."calendar_quarter_number" = 4
      AND s."promo_id" = 999
      AND cn."country_name" = 'United States of America'
)
SELECT p."prod_name" AS "Product_Name",
       ROUND(ABS(
         (COALESCE(sales_2020."total_sales_2020", 0) / total_sales_2020."overall_total_2020") -
         (COALESCE(sales_2019."total_sales_2019", 0) / total_sales_2019."overall_total_2019")
       ), 4) AS "Change_in_Sales_Share"
FROM COMPLEX_ORACLE.COMPLEX_ORACLE.PRODUCTS p
JOIN top_20_percent_products tpp ON p."prod_id" = tpp."prod_id"
LEFT JOIN sales_2019 ON p."prod_id" = sales_2019."prod_id"
LEFT JOIN sales_2020 ON p."prod_id" = sales_2020."prod_id"
CROSS JOIN total_sales_2019
CROSS JOIN total_sales_2020
ORDER BY "Change_in_Sales_Share" ASC NULLS LAST
LIMIT 1;