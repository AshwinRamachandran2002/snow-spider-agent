WITH italian_customers AS (   -- 1.  All Italian customers
    SELECT  c."cust_id"
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  c
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES  co
           ON c."country_id" = co."country_id"
    WHERE   co."country_name" = 'Italy'
),

dec_2021_sales AS (          -- 2.  All sales that happened in December-2021
    SELECT  s.*
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE.SALES  s
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES  t
           ON s."time_id" = t."time_id"
    WHERE   t."calendar_year"       = 2021
      AND   t."calendar_month_number" = 12
),

profits_per_sale AS (        -- 3.  Profit for every line-item purchased by an Italian customer
    SELECT  s."cust_id",
            s."quantity_sold" * (cst."unit_price" - cst."unit_cost") AS profit
    FROM    dec_2021_sales                       s
    JOIN    italian_customers                    ic  ON s."cust_id"  = ic."cust_id"
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE.COSTS  cst
           ON s."prod_id"    = cst."prod_id"
          AND s."time_id"    = cst."time_id"
          AND s."channel_id" = cst."channel_id"
          AND s."promo_id"   = cst."promo_id"
),

total_profit_per_cust AS (   -- 4.  Total December-2021 profit per Italian customer
    SELECT  "cust_id",
            SUM(profit) AS total_profit
    FROM    profits_per_sale
    GROUP BY "cust_id"
),

bounds AS (                  -- 5.  Overall min & max profit for the bucket limits
    SELECT  MIN(total_profit) AS min_profit,
            MAX(total_profit) AS max_profit
    FROM    total_profit_per_cust
),

bucketed AS (                -- 6.  Put every customer into one of 10 equal-width buckets
    SELECT  tp."cust_id",
            tp.total_profit,
            CASE 
                WHEN width_bucket(tp.total_profit,
                                  b.min_profit,
                                  b.max_profit,
                                  10) = 11         -- value exactly = max_profit
                THEN 10
                ELSE width_bucket(tp.total_profit,
                                  b.min_profit,
                                  b.max_profit,
                                  10)
            END  AS bucket
    FROM   total_profit_per_cust  tp
    CROSS JOIN bounds             b
)

-- 7.  Final report:  one row per bucket
SELECT  bucket                       AS profit_bucket,
        COUNT(*)                     AS number_of_customers,
        MIN(total_profit)            AS min_total_profit,
        MAX(total_profit)            AS max_total_profit
FROM    bucketed
GROUP BY bucket
ORDER BY bucket;