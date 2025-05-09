WITH italian_customers AS (          -- all customers that live in Italy
    SELECT cu.cust_id
    FROM   customers  cu
    JOIN   countries  co ON cu.country_id = co.country_id
    WHERE  co.country_name = 'Italy'
),

-- every Italian sale in December‑2021, with its profit
sales_profit AS (
    SELECT s.cust_id,
           s.quantity_sold * (c.unit_price - c.unit_cost) AS profit
    FROM   sales  s
    JOIN   italian_customers ic ON ic.cust_id = s.cust_id
    JOIN   costs  c
           ON  c.prod_id    = s.prod_id
           AND c.time_id    = s.time_id
           AND c.promo_id   = s.promo_id
           AND c.channel_id = s.channel_id
    WHERE  s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
),

-- total December‑2021 profit per Italian customer (zero if no purchase)
customer_profit AS (
    SELECT ic.cust_id,
           COALESCE(SUM(sp.profit), 0) AS total_profit
    FROM   italian_customers ic
    LEFT JOIN sales_profit sp ON sp.cust_id = ic.cust_id
    GROUP BY ic.cust_id
),

-- range and width for the ten equal buckets
range_vals AS (
    SELECT MIN(total_profit)                           AS min_profit,
           MAX(total_profit)                           AS max_profit,
           (MAX(total_profit) - MIN(total_profit)) / 10.0 AS bucket_width
    FROM   customer_profit
),

-- assign every customer to a bucket (1‑10)
bucketed AS (
    SELECT cp.cust_id,
           cp.total_profit,
           CASE
               WHEN rv.bucket_width = 0 THEN 1                          -- all profits identical
               ELSE MIN( CAST( (cp.total_profit - rv.min_profit) / rv.bucket_width AS INTEGER) + 1, 10)
           END AS bucket
    FROM   customer_profit cp
    CROSS  JOIN range_vals rv
),

-- final aggregation per bucket
final AS (
    SELECT bucket,
           COUNT(*)                AS customer_count,
           MIN(total_profit)       AS min_bucket_profit,
           MAX(total_profit)       AS max_bucket_profit
    FROM   bucketed
    GROUP BY bucket
)

SELECT *
FROM   final
ORDER  BY bucket;