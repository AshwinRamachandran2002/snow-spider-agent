/*  Highest and lowest December-2021 profits for Italian customers,
    split into 10 evenly sized tiers (deciles)                      */
WITH "ITALIAN_CUSTOMERS" AS (
    SELECT c."cust_id"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"   c
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"   cn
          ON c."country_id" = cn."country_id"
    WHERE cn."country_name" = 'Italy'
),
"DEC2021_SALES" AS (
    SELECT s."cust_id",
           s."prod_id",
           s."channel_id",
           s."promo_id",
           s."time_id",
           s."quantity_sold",
           s."amount_sold"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"  s
    JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"  t
          ON s."time_id" = t."time_id"
    WHERE t."calendar_year"        = 2021
      AND t."calendar_month_number" = 12
      AND s."cust_id" IN (SELECT "cust_id" FROM "ITALIAN_CUSTOMERS")
),
"PROFIT_PER_SALE" AS (
    SELECT ds."cust_id",
           ( ds."amount_sold"
             - COALESCE(cst."unit_cost",0) * ds."quantity_sold" ) AS "profit"
    FROM "DEC2021_SALES"                                   ds
    LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS"  cst
           ON ds."prod_id"   = cst."prod_id"
          AND ds."time_id"   = cst."time_id"
          AND ds."channel_id"= cst."channel_id"
          AND ds."promo_id"  = cst."promo_id"
),
"CUSTOMER_PROFIT" AS (
    SELECT "cust_id",
           SUM("profit") AS "total_profit"
    FROM "PROFIT_PER_SALE"
    GROUP BY "cust_id"
),
"CUSTOMER_TIERS" AS (
    SELECT "cust_id",
           "total_profit",
           NTILE(10) OVER (ORDER BY "total_profit" DESC) AS "tier"
    FROM "CUSTOMER_PROFIT"
)
SELECT   "tier",
         MIN("total_profit") AS "lowest_profit",
         MAX("total_profit") AS "highest_profit"
FROM     "CUSTOMER_TIERS"
GROUP BY "tier"
ORDER BY "tier";