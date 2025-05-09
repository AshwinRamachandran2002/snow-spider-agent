WITH total_profit_per_customer AS (
    SELECT s."cust_id",
           ROUND(SUM(s."amount_sold" - (s."quantity_sold" * cst."unit_cost")), 4) AS "total_profit"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c
      ON s."cust_id" = c."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" ct
      ON c."country_id" = ct."country_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t
      ON s."time_id" = t."time_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COSTS" cst
      ON s."prod_id" = cst."prod_id"
     AND s."time_id" = cst."time_id"
    WHERE ct."country_name" = 'Italy'
      AND t."calendar_month_number" = 12
      AND t."calendar_year" = 2021
    GROUP BY s."cust_id"
),
min_max_profit AS (
    SELECT MIN("total_profit") AS "min_profit",
           MAX("total_profit") AS "max_profit"
    FROM total_profit_per_customer
),
profit_intervals AS (
    SELECT "min_profit",
           "max_profit",
           ("max_profit" - "min_profit") / 10.0 AS "profit_interval"
    FROM min_max_profit
),
customer_buckets AS (
    SELECT tpc."cust_id",
           tpc."total_profit",
           CASE
               WHEN pi."profit_interval" = 0 THEN 1
               WHEN tpc."total_profit" = pi."max_profit" THEN 10
               ELSE FLOOR((tpc."total_profit" - pi."min_profit") / pi."profit_interval") + 1
           END AS "profit_bucket"
    FROM total_profit_per_customer tpc
    CROSS JOIN profit_intervals pi
)
SELECT CAST("profit_bucket" AS INT) AS "Profit_bucket",
       COUNT(*) AS "Number_of_customers",
       ROUND(MAX("total_profit"), 4) AS "Max_profit",
       ROUND(MIN("total_profit"), 4) AS "Min_profit"
FROM customer_buckets
GROUP BY "profit_bucket"
ORDER BY "profit_bucket";