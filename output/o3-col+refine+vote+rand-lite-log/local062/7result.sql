WITH italian_customers AS (
    SELECT c.cust_id
    FROM customers AS c
    JOIN countries  AS co ON c.country_id = co.country_id
    WHERE co.country_name = 'Italy'
),
sales_profit AS (
    SELECT  s.cust_id,
            (s.quantity_sold * (ct.unit_price - ct.unit_cost)) AS profit
    FROM   sales AS s
    JOIN   costs AS ct
           ON  s.prod_id    = ct.prod_id
           AND s.time_id    = ct.time_id
           AND s.channel_id = ct.channel_id
           AND s.promo_id   = ct.promo_id
    WHERE  s.cust_id IN (SELECT cust_id FROM italian_customers)
      AND  s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
),
customer_profit AS (
    SELECT cust_id,
           SUM(profit) AS total_profit
    FROM   sales_profit
    GROUP  BY cust_id
),
stats AS (
    SELECT MIN(total_profit)                                      AS min_p,
           MAX(total_profit)                                      AS max_p,
           (MAX(total_profit) - MIN(total_profit)) / 10.0         AS width
    FROM   customer_profit
),
profits_with_bucket AS (
    SELECT cp.*,
           CASE
             WHEN (SELECT width FROM stats) = 0
                  THEN 1                                                -- all profits equal
             WHEN cp.total_profit = (SELECT max_p FROM stats)
                  THEN 10                                               -- ensure max value falls into bucket 10
             ELSE CAST( ((cp.total_profit - (SELECT min_p FROM stats)) /
                         (SELECT width FROM stats)) AS INTEGER ) + 1
           END AS bucket_no
    FROM   customer_profit AS cp
)
SELECT bucket_no      AS bucket,
       COUNT(*)       AS customer_count,
       MIN(total_profit) AS bucket_min_profit,
       MAX(total_profit) AS bucket_max_profit
FROM   profits_with_bucket
GROUP  BY bucket_no
ORDER BY bucket_no;