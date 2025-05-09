WITH customer_profits AS (
  SELECT s."cust_id", SUM(s."quantity_sold" * (c."unit_price" - c."unit_cost")) AS "total_profit"
  FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES s
  INNER JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COSTS c ON s."prod_id" = c."prod_id" AND s."time_id" = c."time_id"
  INNER JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS cu ON s."cust_id" = cu."cust_id"
  INNER JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES co ON cu."country_id" = co."country_id"
  INNER JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES t ON s."time_id" = t."time_id"
  WHERE co."country_name" = 'Italy'
    AND t."calendar_month_number" = 12 AND t."calendar_year" = 2021
  GROUP BY s."cust_id"
),
profit_range AS (
  SELECT MIN("total_profit") AS "min_profit", MAX("total_profit") AS "max_profit" FROM customer_profits
),
bucketed_customers AS (
  SELECT 
    cp."cust_id", 
    cp."total_profit",
    CASE 
      WHEN pr."max_profit" = pr."min_profit" THEN 1
      ELSE LEAST( 
        FLOOR( ((cp."total_profit" - pr."min_profit") / NULLIF(pr."max_profit" - pr."min_profit", 0)) * 10 ) + 1,
        10
      )
    END AS "bucket_number"
  FROM customer_profits cp
  CROSS JOIN profit_range pr
)
SELECT 
  bc."bucket_number" AS "Bucket_Number",
  COUNT(*) AS "Number_of_Customers",
  ROUND(MIN(bc."total_profit"), 4) AS "Min_Total_Profit",
  ROUND(MAX(bc."total_profit"), 4) AS "Max_Total_Profit"
FROM bucketed_customers bc
GROUP BY bc."bucket_number"
ORDER BY bc."bucket_number";