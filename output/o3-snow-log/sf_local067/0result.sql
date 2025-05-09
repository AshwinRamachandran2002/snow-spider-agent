WITH "ITALIAN_CUSTOMERS" AS (
    SELECT  c."cust_id"
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"       c
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"       ct
           ON c."country_id" = ct."country_id"
    WHERE   ct."country_name" = 'Italy'
),
"DECEMBER_SALES" AS (
    SELECT  s."cust_id",
            s."prod_id",
            s."time_id",
            s."channel_id",
            s."promo_id",
            s."quantity_sold",
            s."amount_sold"
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"           s
    JOIN    "ITALIAN_CUSTOMERS"                             ic
           ON s."cust_id" = ic."cust_id"
    WHERE   s."time_id" BETWEEN '2021-12-01' AND '2021-12-31'
),
"PROFIT_PER_ROW" AS (
    SELECT  ds."cust_id",
            (ds."amount_sold" - (co."unit_cost" * ds."quantity_sold")) AS "profit_row"
    FROM    "DECEMBER_SALES"                                ds
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS"           co
           ON ds."prod_id"    = co."prod_id"
          AND ds."time_id"    = co."time_id"
          AND ds."channel_id" = co."channel_id"
          AND ds."promo_id"   = co."promo_id"
),
"PROFIT_PER_CUSTOMER" AS (
    SELECT  "cust_id",
            SUM("profit_row") AS "customer_profit"
    FROM    "PROFIT_PER_ROW"
    GROUP BY "cust_id"
),
"PROFIT_WITH_TIER" AS (
    SELECT  "cust_id",
            "customer_profit",
            NTILE(10) OVER (ORDER BY "customer_profit") AS "tier"
    FROM    "PROFIT_PER_CUSTOMER"
)
SELECT  "tier",
        MIN("customer_profit") AS "lowest_profit",
        MAX("customer_profit") AS "highest_profit"
FROM    "PROFIT_WITH_TIER"
GROUP BY "tier"
ORDER BY "tier";