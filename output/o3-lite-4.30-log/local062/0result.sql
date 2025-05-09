WITH italy_id AS (                         -- Italy
    SELECT country_id
    FROM   countries
    WHERE  country_name = 'Italy'
),
/* Italian sales in December‑2021 with profit per transaction */
sale_profit AS (
    SELECT s.cust_id,
           s.quantity_sold * (co.unit_price - co.unit_cost) AS profit
    FROM   sales     AS s
    JOIN   customers AS c  ON c.cust_id   = s.cust_id
    JOIN   italy_id  AS i  ON i.country_id = c.country_id
    JOIN   costs     AS co ON co.prod_id   = s.prod_id
                          AND co.time_id   = s.time_id
    JOIN   times     AS t  ON t.time_id    = s.time_id
    WHERE  t.calendar_month_number = 12
      AND  t.calendar_year         = 2021
),
/* total December‑2021 profit per Italian customer */
cust_profit AS (
    SELECT cust_id,
           SUM(profit) AS total_profit
    FROM   sale_profit
    GROUP  BY cust_id
),
/* overall range and equal‑width step */
limits AS (
    SELECT MIN(total_profit)                         AS min_p,
           MAX(total_profit)                         AS max_p,
           (MAX(total_profit) - MIN(total_profit)) / 10.0 AS step
    FROM   cust_profit
),
/* assign bucket 1‑10 */
bucketed AS (
    SELECT cp.cust_id,
           cp.total_profit,
           CASE
               WHEN cp.total_profit = (SELECT max_p FROM limits) THEN 10
               ELSE CAST( (cp.total_profit - (SELECT min_p FROM limits)) /
                          (SELECT step FROM limits) AS INTEGER) + 1
           END AS bucket
    FROM   cust_profit AS cp
),
/* ensure all buckets appear even when empty */
buckets AS (
    SELECT 1 AS bucket UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
    SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
    SELECT 9 UNION ALL SELECT 10
)
SELECT b.bucket                              AS bucket_number,
       COUNT(bt.cust_id)                     AS customer_count,
       ROUND(MIN(bt.total_profit),4)         AS min_total_profit,
       ROUND(MAX(bt.total_profit),4)         AS max_total_profit
FROM   buckets  AS b
LEFT   JOIN bucketed AS bt ON bt.bucket = b.bucket
GROUP  BY b.bucket
ORDER  BY b.bucket;