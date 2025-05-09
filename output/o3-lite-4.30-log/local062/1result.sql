WITH italian_customers AS (
    SELECT cu.cust_id
    FROM customers cu
    JOIN countries co ON cu.country_id = co.country_id
    WHERE co.country_name = 'Italy'
),
cust_profit AS (
    SELECT  s.cust_id,
            SUM(s.quantity_sold * (c.unit_price - c.unit_cost)) AS total_profit
    FROM    sales  s
    JOIN    costs  c
           ON  c.prod_id    = s.prod_id
           AND c.time_id    = s.time_id
           AND c.promo_id   = s.promo_id
           AND c.channel_id = s.channel_id
    WHERE   s.cust_id IN (SELECT cust_id FROM italian_customers)
      AND   s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
    GROUP BY s.cust_id
),
limits AS (
    SELECT MIN(total_profit) AS min_p,
           MAX(total_profit) AS max_p
    FROM   cust_profit
),
bucketed AS (
    SELECT cp.cust_id,
           cp.total_profit,
           CASE
               WHEN (SELECT max_p FROM limits) = (SELECT min_p FROM limits) THEN 10
               WHEN cp.total_profit = (SELECT max_p FROM limits)            THEN 10
               ELSE CAST(
                       ((cp.total_profit - (SELECT min_p FROM limits)) /
                        ((SELECT max_p FROM limits) - (SELECT min_p FROM limits)) * 10)
                       AS INTEGER
                    ) + 1
           END AS bucket_number
    FROM   cust_profit cp
)
SELECT  bucket_number,
        COUNT(*)                     AS customer_count,
        ROUND(MIN(total_profit),4)   AS min_total_profit,
        ROUND(MAX(total_profit),4)   AS max_total_profit
FROM    bucketed
GROUP BY bucket_number
ORDER BY bucket_number;