WITH total_profit_per_customer AS (
  SELECT s."cust_id",
         SUM(ROUND(s."amount_sold" - (c."unit_cost" * s."quantity_sold"), 4)) AS "total_profit"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" cu ON s."cust_id" = cu."cust_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co ON cu."country_id" = co."country_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COSTS" c
    ON s."prod_id" = c."prod_id"
    AND s."time_id" = c."time_id"
    AND s."promo_id" = c."promo_id"
    AND s."channel_id" = c."channel_id"
  WHERE co."country_name" = 'Italy'
    AND t."calendar_year" = 2021
    AND t."calendar_month_number" = 12
  GROUP BY s."cust_id"
),
profit_stats AS (
  SELECT MIN("total_profit") AS "min_profit", MAX("total_profit") AS "max_profit"
  FROM total_profit_per_customer
),
bucketed_customers AS (
  SELECT tp."cust_id",
         tp."total_profit",
         CASE
           WHEN ps."max_profit" = ps."min_profit" THEN 1
           WHEN tp."total_profit" = ps."max_profit" THEN 10
           ELSE FLOOR(((tp."total_profit" - ps."min_profit") * 10) / NULLIF((ps."max_profit" - ps."min_profit"), 0)) + 1
         END AS "Profit_bucket"
  FROM total_profit_per_customer tp
  CROSS JOIN profit_stats ps
)
SELECT "Profit_bucket",
       COUNT("cust_id") AS "Number_of_customers",
       ROUND(MAX("total_profit"), 4) AS "Max_profit",
       ROUND(MIN("total_profit"), 4) AS "Min_profit"
FROM bucketed_customers
GROUP BY "Profit_bucket"
ORDER BY "Profit_bucket";