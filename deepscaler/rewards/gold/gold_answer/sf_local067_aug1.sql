-- Task: Can you provide the highest and lowest total profits among Italian customers in December 2021?
WITH italian_customers AS (
    SELECT c."cust_id"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS c
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES co ON c."country_id" = co."country_id"
    WHERE co."country_name" = 'Italy'
),
december_2021_times AS (
    SELECT t."time_id"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES t
    WHERE t."calendar_year" = 2021 AND t."calendar_month_number" = 12
),
sales_in_december_2021 AS (
    SELECT s.*
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES s
    WHERE s."time_id" IN (SELECT "time_id" FROM december_2021_times)
),
italian_sales_in_december_2021 AS (
    SELECT s.*
    FROM sales_in_december_2021 s
    WHERE s."cust_id" IN (SELECT "cust_id" FROM italian_customers)
),
sales_with_cost AS (
    SELECT s.*, c."unit_cost"
    FROM italian_sales_in_december_2021 s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COSTS c ON
        s."prod_id" = c."prod_id" AND
        s."time_id" = c."time_id" AND
        s."promo_id" = c."promo_id" AND
        s."channel_id" = c."channel_id"
),
sales_with_profit AS (
    SELECT s.*, (s."amount_sold" - (s."quantity_sold" * s."unit_cost")) AS "profit"
    FROM sales_with_cost s
),
customer_profits AS (
    SELECT s."cust_id", SUM(s."profit") AS "total_profit"
    FROM sales_with_profit s
    GROUP BY s."cust_id"
)
SELECT
    MAX(ROUND("total_profit", 4)) AS "Highest_Profit",
    MIN(ROUND("total_profit", 4)) AS "Lowest_Profit"
FROM customer_profits;