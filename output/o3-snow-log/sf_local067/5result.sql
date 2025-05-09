WITH "ITALY_ID" AS (   -- find Italy’s country_id
    SELECT "country_id"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"
    WHERE "country_name" = 'Italy'
),

"ITALIAN_CUSTOMERS" AS (   -- all Italian customers
    SELECT "cust_id"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" c
    JOIN "ITALY_ID" i
      ON c."country_id" = i."country_id"
),

"DEC21_SALES" AS (   -- sales in December-2021 made by Italian customers
    SELECT s."cust_id",
           s."prod_id",
           s."channel_id",
           s."promo_id",
           s."time_id",
           s."quantity_sold",
           s."amount_sold"
    FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
    JOIN "ITALIAN_CUSTOMERS" ic
      ON s."cust_id" = ic."cust_id"
    WHERE TO_DATE(s."time_id") BETWEEN '2021-12-01' AND '2021-12-31'
),

"PROFIT_PER_SALE" AS (   -- profit for every qualifying sale
    SELECT d."cust_id",
           d."amount_sold"
           - COALESCE(c."unit_cost",0) * d."quantity_sold"  AS "profit"
    FROM "DEC21_SALES" d
    LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS" c
           ON  d."prod_id"   = c."prod_id"
           AND d."channel_id"= c."channel_id"
           AND d."promo_id"  = c."promo_id"
           AND d."time_id"   = c."time_id"
),

"PROFIT_PER_CUSTOMER" AS (   -- total December-2021 profit per customer
    SELECT "cust_id",
           SUM("profit") AS "total_profit"
    FROM "PROFIT_PER_SALE"
    GROUP BY "cust_id"
),

"CUSTOMER_TIERS" AS (   -- divide customers into 10 equal tiers (deciles)
    SELECT "cust_id",
           "total_profit",
           NTILE(10) OVER (ORDER BY "total_profit" DESC) AS "profit_tier"
    FROM "PROFIT_PER_CUSTOMER"
)

-- highest & lowest profit in each tier
SELECT   "profit_tier",
         MAX("total_profit") AS "highest_profit",
         MIN("total_profit") AS "lowest_profit"
FROM     "CUSTOMER_TIERS"
GROUP BY "profit_tier"
ORDER BY "profit_tier";