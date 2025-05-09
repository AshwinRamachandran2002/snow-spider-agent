WITH customer_profits AS (
  SELECT
    s."cust_id",
    SUM(s."amount_sold" - s."quantity_sold" * c."unit_cost") AS "total_profit"
  FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COSTS" c
    ON s."prod_id" = c."prod_id" AND s."time_id" = c."time_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" cu
    ON s."cust_id" = cu."cust_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" co
    ON cu."country_id" = co."country_id"
  JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t
    ON s."time_id" = t."time_id"
  WHERE co."country_name" = 'Italy'
    AND t."calendar_year" = 2021
    AND t."calendar_month_number" = 12
  GROUP BY s."cust_id"
),
min_max_profit AS (
  SELECT
    MIN("total_profit") AS "min_profit",
    MAX("total_profit") AS "max_profit"
  FROM customer_profits
),
profit_intervals AS (
  SELECT
    cp."cust_id",
    cp."total_profit",
    ((mm."max_profit" - mm."min_profit") / 10.0) AS "interval_width",
    CASE
      WHEN cp."total_profit" = mm."max_profit" THEN 10
      ELSE FLOOR((cp."total_profit" - mm."min_profit") / ((mm."max_profit" - mm."min_profit") / 10.0)) + 1
    END AS "profit_bucket"
  FROM customer_profits cp
  CROSS JOIN min_max_profit mm
)
SELECT
  pi."profit_bucket" AS "Profit_bucket",
  COUNT(pi."cust_id") AS "Number_of_customers",
  ROUND(MAX(pi."total_profit"), 4) AS "Max_profit",
  ROUND(MIN(pi."total_profit"), 4) AS "Min_profit"
FROM profit_intervals pi
GROUP BY pi."profit_bucket"
ORDER BY pi."profit_bucket";