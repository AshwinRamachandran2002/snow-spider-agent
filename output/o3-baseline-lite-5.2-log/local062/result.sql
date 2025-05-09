/* 1) work only with Italian customers' sales that happened in December‑2021
   2) compute every customer’s total profit for that month
   3) find overall [min , max] profit and the bucket‐width (= range / 10)
   4) put each customer in one of the ten equal‑width buckets
      (value equal to the overall max goes into bucket 10)
   5) report, for every bucket 1‑10, the population size and the
      smallest / largest total‑profit that actually occurred there          */

WITH
-- Italian customers
italian_customers AS (
    SELECT cu.cust_id
    FROM   customers  cu
    JOIN   countries  co ON co.country_id = cu.country_id
    WHERE  co.country_name = 'Italy'
),

-- sales done by those customers in Dec‑2021
it_sales_2021_12 AS (
    SELECT s.*
    FROM   sales           s
    JOIN   italian_customers ic ON ic.cust_id = s.cust_id
    WHERE  strftime('%Y', s.time_id) = '2021'
      AND  strftime('%m', s.time_id) = '12'
),

-- monthly profit of every Italian customer (Σ qty × (price − cost))
customer_profit AS (
    SELECT s.cust_id,
           SUM( s.quantity_sold * (c.unit_price - c.unit_cost) ) AS total_profit
    FROM   it_sales_2021_12  s
    JOIN   costs             c
           ON  c.prod_id    = s.prod_id
           AND c.time_id    = s.time_id
           AND c.channel_id = s.channel_id
           AND c.promo_id   = s.promo_id
    GROUP  BY s.cust_id
),

-- overall min, max and equal bucket width
bounds AS (
    SELECT MIN(total_profit)                            AS min_p,
           MAX(total_profit)                            AS max_p,
           (MAX(total_profit) - MIN(total_profit)) / 10.0 AS w
    FROM   customer_profit
),

-- assign bucket 1‑10 to every customer
bucketed AS (
    SELECT cp.cust_id,
           cp.total_profit,
           CASE
               WHEN b.max_p = b.min_p        THEN 1                           -- all equal
               WHEN cp.total_profit = b.max_p THEN 10                         -- very top value
               ELSE CAST( ((cp.total_profit - b.min_p) * 10.0 
                           / (b.max_p - b.min_p)) AS INTEGER ) + 1
           END AS bucket
    FROM   customer_profit cp
    CROSS  JOIN bounds b
),

-- generator for buckets 1‑10 so that even empty buckets appear
seq(n) AS (
    SELECT 1 UNION ALL
    SELECT n+1 FROM seq WHERE n < 10
)

-- final stats per bucket
SELECT  s.n                       AS bucket,
        COUNT(b.cust_id)          AS num_customers,
        ROUND( MIN(b.total_profit), 4 ) AS min_total_profit,
        ROUND( MAX(b.total_profit), 4 ) AS max_total_profit
FROM    seq            s
LEFT    JOIN bucketed   b ON b.bucket = s.n
GROUP   BY s.n
ORDER   BY s.n;