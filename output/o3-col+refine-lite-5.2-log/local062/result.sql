WITH italian_customers AS (
    SELECT cu.cust_id
    FROM customers  AS cu
    JOIN countries  AS co ON co.country_id = cu.country_id
    WHERE co.country_name = 'Italy'
),
customer_profit AS (
    SELECT s.cust_id,
           SUM(s.quantity_sold * (c.unit_price - c.unit_cost)) AS total_profit
    FROM sales AS s
    JOIN costs AS c
      ON c.prod_id   = s.prod_id
     AND c.time_id   = s.time_id
     AND c.channel_id = s.channel_id
     AND c.promo_id   = s.promo_id
    WHERE s.cust_id IN (SELECT cust_id FROM italian_customers)
      AND s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
    GROUP BY s.cust_id
),
bounds AS (
    SELECT MIN(total_profit) AS min_p,
           MAX(total_profit) AS max_p
    FROM customer_profit
),
bucketed AS (
    SELECT cp.cust_id,
           cp.total_profit,
           CASE
               WHEN b.max_p = b.min_p               THEN 1               -- all profits identical
               WHEN cp.total_profit = b.max_p       THEN 10              -- put absolute max in bucket‑10
               ELSE 1 + CAST(((cp.total_profit - b.min_p) * 10.0) /
                             (b.max_p - b.min_p) AS INTEGER)
           END AS bucket
    FROM customer_profit AS cp, bounds AS b
)
SELECT bucket            AS profit_bucket,
       COUNT(*)          AS number_of_customers,
       MIN(total_profit) AS min_total_profit,
       MAX(total_profit) AS max_total_profit
FROM bucketed
GROUP BY bucket
ORDER BY bucket;