WITH "italian_customers" AS (
    SELECT c."cust_id"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" cnt
          ON c."country_id" = cnt."country_id"
    WHERE cnt."country_name" = 'Italy'
),
"dec2021_sales" AS (
    SELECT s."cust_id",
           s."prod_id",
           s."time_id",
           s."quantity_sold",
           s."amount_sold"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
    WHERE s."time_id" BETWEEN '2021-12-01' AND '2021-12-31'
),
"cust_profit" AS (
    SELECT ds."cust_id",
           SUM(ds."amount_sold" - co."unit_cost" * ds."quantity_sold") AS "profit"
    FROM "dec2021_sales" ds
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS" co
          ON co."prod_id" = ds."prod_id"
         AND co."time_id" = ds."time_id"
    GROUP BY ds."cust_id"
),
"ranked" AS (
    SELECT cp."cust_id",
           cp."profit",
           NTILE(10) OVER (ORDER BY cp."profit") AS "profit_tier"
    FROM "cust_profit" cp
    JOIN "italian_customers" ic
          ON cp."cust_id" = ic."cust_id"
)
SELECT "profit_tier",
       ROUND(MAX("profit"),4) AS "highest_profit",
       ROUND(MIN("profit"),4) AS "lowest_profit"
FROM "ranked"
GROUP BY "profit_tier"
ORDER BY "profit_tier";