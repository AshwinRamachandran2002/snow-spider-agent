WITH italian_customers AS (   -- all customers that live in Italy
    SELECT c."cust_id"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  c
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"  ct
           ON c."country_id" = ct."country_id"
    WHERE  ct."country_name" = 'Italy'
),    
december_sales AS (          -- sales that happened in December-2021
    SELECT s.*
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"  s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"  t
           ON s."time_id" = t."time_id"
    WHERE  t."calendar_year"       = 2021
      AND  t."calendar_month_number" = 12
),    
profit_per_customer AS (     -- monthly profit of each Italian customer
    SELECT ic."cust_id",
           SUM( s."quantity_sold" * 
                (co."unit_price" - co."unit_cost") )  AS total_profit
    FROM   italian_customers               ic
    JOIN   december_sales                  s   ON s."cust_id" = ic."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS" co
           ON  co."prod_id"   = s."prod_id"
           AND co."time_id"   = s."time_id"
           AND co."channel_id"= s."channel_id"
           AND co."promo_id"  = s."promo_id"
    GROUP  BY ic."cust_id"
),    
stats AS (                    -- global min/max & bucket width
    SELECT MIN(total_profit)                                                AS min_profit,
           MAX(total_profit)                                                AS max_profit,
           (MAX(total_profit) - MIN(total_profit)) / 10.0                  AS interval_width
    FROM   profit_per_customer
),    
bucketed AS (                 -- assign each customer to one of 10 buckets
    SELECT p."cust_id",
           p.total_profit,
           CASE 
               WHEN p.total_profit = st.max_profit THEN 10
               ELSE 1 + FLOOR( (p.total_profit - st.min_profit) / st.interval_width )
           END                                                    AS bucket_id
    FROM   profit_per_customer p
    CROSS  JOIN stats           st
)
SELECT  b.bucket_id                             AS "BUCKET",
        COUNT(*)                                AS "NUM_CUSTOMERS",
        ROUND( MIN(b.total_profit), 4 )         AS "MIN_TOTAL_PROFIT",
        ROUND( MAX(b.total_profit), 4 )         AS "MAX_TOTAL_PROFIT"
FROM    bucketed b
GROUP   BY b.bucket_id
ORDER   BY b.bucket_id;