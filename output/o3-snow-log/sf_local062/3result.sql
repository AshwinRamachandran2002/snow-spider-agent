WITH "ITALIAN_CUSTOMERS" AS (   -- all customers whose country is Italy
    SELECT  c."cust_id"
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"   c
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"   co
           ON c."country_id" = co."country_id"
    WHERE   co."country_name" = 'Italy'
),
"DEC21_SALES" AS (             -- sales that happened in December-2021
    SELECT  s.*
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"  s
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"  t
           ON s."time_id" = t."time_id"
    WHERE   t."calendar_year"        = 2021
      AND   t."calendar_month_number" = 12
),
"SALES_COSTS" AS (             -- attach unit_price & unit_cost to every sale
    SELECT  ds."cust_id",
            ds."quantity_sold",
            cst."unit_price",
            cst."unit_cost",
            ds."quantity_sold" * (cst."unit_price" - cst."unit_cost")  AS "profit"
    FROM    "DEC21_SALES"                       ds
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS"  cst
           ON ds."prod_id" = cst."prod_id"
          AND ds."time_id" = cst."time_id"
),
"CUSTOMER_PROFIT" AS (         -- total December-2021 profit per Italian customer
    SELECT  ic."cust_id",
            COALESCE(SUM(sc."profit"),0) AS "total_profit"
    FROM    "ITALIAN_CUSTOMERS" ic
    LEFT JOIN "SALES_COSTS"    sc
           ON ic."cust_id" = sc."cust_id"
    GROUP BY ic."cust_id"
),
"STATS" AS (                   -- overall min & max profit
    SELECT  MIN("total_profit") AS "min_profit",
            MAX("total_profit") AS "max_profit"
    FROM    "CUSTOMER_PROFIT"
),
"BUCKETED" AS (                -- assign each customer to one of 10 equal-width buckets
    SELECT  cp."cust_id",
            cp."total_profit",
            s."min_profit",
            s."max_profit",
            (s."max_profit" - s."min_profit") / 10.0           AS "width",
            CASE
                WHEN s."max_profit" = s."min_profit"
                     THEN 1                                       -- all profits identical
                ELSE LEAST( 10 ,
                            FLOOR( (cp."total_profit" - s."min_profit")
                                   / ((s."max_profit" - s."min_profit") / 10.0) ) + 1 )
            END                                                  AS "bucket_num"
    FROM    "CUSTOMER_PROFIT" cp
    CROSS JOIN "STATS"        s
)
SELECT  "bucket_num",
        COUNT(*)                       AS "customer_count",
        MIN("total_profit")            AS "min_bucket_profit",
        MAX("total_profit")            AS "max_bucket_profit"
FROM    "BUCKETED"
GROUP BY "bucket_num"
ORDER BY "bucket_num";