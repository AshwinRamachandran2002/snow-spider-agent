WITH customer_profits AS (
  SELECT s."cust_id",
         SUM(s."quantity_sold" * (c."unit_price" - c."unit_cost")) AS "total_profit"
  FROM "sales" AS s
  JOIN "costs" AS c ON s."prod_id" = c."prod_id" AND s."time_id" = c."time_id"
  JOIN "customers" AS cu ON s."cust_id" = cu."cust_id"
  JOIN "countries" AS co ON cu."country_id" = co."country_id"
  JOIN "times" AS t ON s."time_id" = t."time_id"
  WHERE co."country_iso_code" = 'IT'
    AND t."calendar_year" = 2021
    AND t."calendar_month_number" = 12
  GROUP BY s."cust_id"
),
profit_range AS (
  SELECT MIN("total_profit") AS "min_profit",
         MAX("total_profit") AS "max_profit"
  FROM customer_profits
),
bucketed_customers AS (
  SELECT cp."cust_id",
         cp."total_profit",
         CASE
           WHEN cp."total_profit" = pr."max_profit" THEN 10
           ELSE CAST( ((cp."total_profit" - pr."min_profit") * 10.0 / (pr."max_profit" - pr."min_profit") + 1) AS INTEGER )
         END AS "bucket_number"
  FROM customer_profits cp, profit_range pr
)
SELECT
  bc."bucket_number" AS "Bucket_Number",
  COUNT(*) AS "Number_of_Customers",
  MIN(ROUND(bc."total_profit", 4)) AS "Min_Total_Profit",
  MAX(ROUND(bc."total_profit", 4)) AS "Max_Total_Profit"
FROM bucketed_customers bc
GROUP BY bc."bucket_number"
ORDER BY bc."bucket_number";