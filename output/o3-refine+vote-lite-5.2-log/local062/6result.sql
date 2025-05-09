WITH italian_customers AS (
    SELECT cu.cust_id
    FROM customers  cu
    JOIN countries  co ON cu.country_id = co.country_id
    WHERE co.country_name = 'Italy'
),
cust_month_profit AS (
    /* total profit per Italian customer for December‑2021 */
    SELECT  s.cust_id,
            SUM( s.quantity_sold * (c.unit_price - c.unit_cost) ) AS total_profit
    FROM   sales  s
    JOIN   costs  c  ON  c.prod_id   = s.prod_id
                    AND c.time_id   = s.time_id
                    AND c.channel_id= s.channel_id
                    AND c.promo_id  = s.promo_id
    JOIN   italian_customers ic ON ic.cust_id = s.cust_id
    WHERE  s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
    GROUP  BY s.cust_id
),
range_stats AS (
    /* overall range and bucket width */
    SELECT MIN(total_profit)                        AS min_profit,
           MAX(total_profit)                        AS max_profit,
           (MAX(total_profit) - MIN(total_profit)) / 10.0 AS width
    FROM   cust_month_profit
),
bucketed AS (
    /* assign each customer to a bucket 0‑9 */
    SELECT cmp.cust_id,
           cmp.total_profit,
           CASE
               WHEN rs.width = 0                  THEN 0
               WHEN cmp.total_profit = rs.max_profit THEN 9   -- ensure max lands in last bucket
               ELSE CAST( (cmp.total_profit - rs.min_profit) / rs.width AS INTEGER )
           END AS bucket
    FROM   cust_month_profit cmp
    CROSS  JOIN range_stats  rs
)
SELECT  bucket + 1                         AS bucket_number,      -- 1‑10
        COUNT(*)                           AS customer_count,
        MIN(total_profit)                  AS bucket_min_profit,
        MAX(total_profit)                  AS bucket_max_profit
FROM    bucketed
GROUP   BY bucket
ORDER   BY bucket;