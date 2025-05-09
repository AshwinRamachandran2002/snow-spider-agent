/*------------------------------------------------------------
  Italian customers – profit buckets for December 2021
  (profit = quantity_sold * (unit_price – unit_cost) )
  ------------------------------------------------------------*/
WITH italian_customers AS (
    SELECT c."cust_id"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  c
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"  co
           ON c."country_id" = co."country_id"
    WHERE  co."country_name" = 'Italy'
),  

dec2021_days AS (
    SELECT "time_id"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"
    WHERE  "calendar_month_number" = 12
      AND  "calendar_year"        = 2021
),  

cust_profit AS (     -- total December-2021 profit per Italian customer
    SELECT  s."cust_id",
            SUM( s."quantity_sold" * ( ct."unit_price" - ct."unit_cost" ) ) AS total_profit
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"  s
    JOIN    italian_customers                      ic ON s."cust_id"  = ic."cust_id"
    JOIN    dec2021_days                           d  ON s."time_id"  = d."time_id"
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS" ct
           ON  s."prod_id"    = ct."prod_id"
           AND s."time_id"    = ct."time_id"
           AND s."channel_id" = ct."channel_id"
           AND s."promo_id"   = ct."promo_id"
    GROUP BY s."cust_id"
),  

range_vals AS (      -- overall min / max profit
    SELECT MIN(total_profit) AS min_profit,
           MAX(total_profit) AS max_profit
    FROM   cust_profit
),  

bucketed AS (        -- assign each customer to one of 10 equal-width buckets
    SELECT  cp."cust_id",
            cp.total_profit,
            CASE
                WHEN rv.max_profit = rv.min_profit THEN 0
                ELSE LEAST(
                         FLOOR(
                             ( cp.total_profit - rv.min_profit )
                             / ( ( rv.max_profit - rv.min_profit ) / 10 )
                         ),
                         9
                     )
            END AS bucket_id          -- 0 … 9
    FROM    cust_profit cp
    CROSS JOIN range_vals rv
)

SELECT  bucket_id + 1            AS bucket_number,    -- 1 … 10
        COUNT(*)                 AS customer_count,
        MIN(total_profit)        AS bucket_min_profit,
        MAX(total_profit)        AS bucket_max_profit
FROM    bucketed
GROUP BY bucket_id
ORDER BY bucket_number;