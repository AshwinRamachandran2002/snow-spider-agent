/*---------------------------------------------------------------------------
Group every Italian customer into ten profit buckets for December-2021.
For every bucket return: bucket number (0-9), number of customers in it,
and the minimum / maximum total profit that customers in that bucket made.
---------------------------------------------------------------------------*/
WITH italian_customers AS (     -- 1) all customers whose country is Italy
    SELECT cu."cust_id"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  cu
           JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co
             ON cu."country_id" = co."country_id"
    WHERE  co."country_name" = 'Italy'
),

customer_profits AS (           -- 2) total December-2021 profit per customer
    SELECT  ic."cust_id",
            COALESCE( SUM( s."quantity_sold"
                           * ( cs."unit_price" - cs."unit_cost") ), 0 ) 
            AS total_profit
    FROM    italian_customers                         ic
            LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"  s
                   ON  ic."cust_id" = s."cust_id"
                   AND s."time_id" BETWEEN '2021-12-01' AND '2021-12-31'
            LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS"  cs
                   ON  s."prod_id" = cs."prod_id"
                   AND s."time_id" = cs."time_id"
    GROUP BY ic."cust_id"
),

stats AS (                      -- 3) overall min, max and equal interval size
    SELECT  MIN(total_profit)                                                AS min_profit,
            MAX(total_profit)                                                AS max_profit,
            CASE WHEN MAX(total_profit) = MIN(total_profit) 
                 THEN 0 
                 ELSE (MAX(total_profit) - MIN(total_profit)) / 10 END       AS interval_width
    FROM    customer_profits
),

bucketed AS (                   -- 4) assign every customer to a bucket 0-9
    SELECT  cp."cust_id",
            cp.total_profit,
            CASE 
                WHEN st.interval_width = 0 THEN 0
                ELSE LEAST(9, FLOOR( (cp.total_profit - st.min_profit)
                                    / st.interval_width ))
            END                                                   AS bucket_num
    FROM    customer_profits cp
            CROSS JOIN stats st
),

bucket_summary AS (             -- 5) aggregate information per bucket
    SELECT  b.bucket_num,
            COUNT(*)                     AS num_customers,
            MIN(b.total_profit)          AS bucket_min_profit,
            MAX(b.total_profit)          AS bucket_max_profit
    FROM    bucketed b
    GROUP BY b.bucket_num
)

SELECT  bs.bucket_num        AS bucket_number,
        bs.num_customers,
        bs.bucket_min_profit,
        bs.bucket_max_profit
FROM    bucket_summary bs
ORDER BY bs.bucket_num ASC;