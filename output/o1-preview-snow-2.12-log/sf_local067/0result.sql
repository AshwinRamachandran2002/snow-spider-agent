WITH italian_customers AS (
    SELECT cu."cust_id"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" cu
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co ON cu."country_id" = co."country_id"
    WHERE co."country_name" = 'Italy'
),
sales_dec2021 AS (
    SELECT s."cust_id", s."prod_id", s."time_id", s."promo_id", s."channel_id", s."quantity_sold", s."amount_sold"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
    WHERE t."calendar_year" = 2021 AND t."calendar_month_number" = 12
),
italian_sales_dec2021 AS (
    SELECT s.*
    FROM sales_dec2021 s
    JOIN italian_customers ic ON s."cust_id" = ic."cust_id"
),
sales_with_cost AS (
    SELECT s.*, c."unit_cost"
    FROM italian_sales_dec2021 s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COSTS" c
        ON s."prod_id" = c."prod_id"
        AND s."time_id" = c."time_id"
        AND s."promo_id" = c."promo_id"
        AND s."channel_id" = c."channel_id"
),
sales_with_profit AS (
    SELECT
        s."cust_id",
        s."amount_sold",
        s."quantity_sold",
        s."amount_sold" - (s."quantity_sold" * s."unit_cost") AS profit
    FROM sales_with_cost s
),
customer_profits AS (
    SELECT
        "cust_id",
        SUM(profit) AS total_profit
    FROM sales_with_profit
    GROUP BY "cust_id"
),
customer_profits_ranked AS (
    SELECT
        cp."cust_id",
        cp.total_profit,
        NTILE(10) OVER (ORDER BY cp.total_profit DESC NULLS LAST) AS tier
    FROM customer_profits cp
)
SELECT
    tier,
    ROUND(MAX(total_profit), 4) AS "Highest_Profit",
    ROUND(MIN(total_profit), 4) AS "Lowest_Profit"
FROM customer_profits_ranked
GROUP BY tier
ORDER BY tier;