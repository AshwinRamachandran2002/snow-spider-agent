/* 1)  Italian customers
   2)  Sales lines for December-2021
   3)  Profit per customer  ( Σ qty * (price-cost) )
   4)  Overall min/max profit to build 10 equal-width buckets
   5)  Place each customer into a bucket (0-9) – bucket 0 = lowest
   6)  Report, for every bucket that contains at least one customer,
       the bucket ordinal (1-10), number of customers and
       the min / max total profit observed inside that bucket      */

WITH  it_customers AS (          -- all Italian customers
        SELECT  c."cust_id"
        FROM    COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  c
        JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"  co
                 ON c."country_id" = co."country_id"
        WHERE   co."country_name" = 'Italy'
),
dec21_sales AS (                 -- sales lines that happened in Dec-2021
        SELECT  s.*
        FROM    COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"  s
        JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"  t
                 ON s."time_id" = t."time_id"
        WHERE   t."calendar_year"       = 2021
          AND   t."calendar_month_number" = 12
),
profit_per_cust AS (             -- total December profit per Italian customer
        SELECT  s."cust_id",
                SUM( s."quantity_sold"
                     * (cst."unit_price" - cst."unit_cost") )     AS total_profit
        FROM         dec21_sales            s
        JOIN         COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS" cst
                      ON  s."prod_id"    = cst."prod_id"
                      AND s."time_id"    = cst."time_id"
                      AND s."channel_id" = cst."channel_id"
                      AND s."promo_id"   = cst."promo_id"
        JOIN         it_customers         ic
                      ON  s."cust_id"     = ic."cust_id"
        GROUP BY     s."cust_id"
),
stats AS (                       -- min / max profit across all Italian customers
        SELECT  MIN(total_profit) AS min_profit,
                MAX(total_profit) AS max_profit
        FROM    profit_per_cust
),
bucketed AS (                    -- assign each customer to one of 10 equal-width buckets
        SELECT
               CASE
                   WHEN (stats.max_profit - stats.min_profit) = 0
                        THEN 0                                            -- all profits equal
                   ELSE LEAST(
                            9,
                            FLOOR(  (p.total_profit - stats.min_profit)
                                    / ((stats.max_profit - stats.min_profit) / 10) )
                        )
               END                                         AS bucket_num, -- 0-9
               p.total_profit
        FROM   profit_per_cust p
        CROSS  JOIN stats
)
SELECT  bucket_num + 1                              AS bucket_position,   -- 1-10
        COUNT(*)                                    AS customer_count,
        MIN(total_profit)                           AS bucket_min_total_profit,
        MAX(total_profit)                           AS bucket_max_total_profit
FROM    bucketed
GROUP BY bucket_num
ORDER BY bucket_position;