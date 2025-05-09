WITH italian_customers AS (
    SELECT c.cust_id
    FROM customers       AS c
    JOIN countries       AS cn ON c.country_id = cn.country_id
    WHERE cn.country_iso_code = 'IT'          -- all Italian customers
),

dec21_sales AS (
    SELECT s.*
    FROM sales  AS s
    JOIN times  AS t ON s.time_id = t.time_id
    WHERE t.calendar_year = 2021              -- December 2021
      AND t.calendar_month_number = 12
),

profit_per_row AS (
    /* profit = quantity_sold × (unit_price – unit_cost) */
    SELECT s.cust_id,
           s.quantity_sold * (co.unit_price - co.unit_cost) AS profit
    FROM dec21_sales AS s
    JOIN italian_customers AS ic ON s.cust_id = ic.cust_id
    JOIN costs            AS co
         ON  s.prod_id   = co.prod_id
        AND s.time_id    = co.time_id
        AND s.channel_id = co.channel_id
        AND s.promo_id   = co.promo_id
),

customer_profit AS (
    SELECT cust_id,
           SUM(profit) AS total_profit
    FROM profit_per_row
    GROUP BY cust_id
),

min_max AS (
    SELECT MIN(total_profit)                         AS min_profit,
           MAX(total_profit)                         AS max_profit,
           (MAX(total_profit) - MIN(total_profit))/10.0 AS interval_w
    FROM customer_profit
),

bucketed AS (
    /* assign every customer to one of the ten equal‑width buckets (0‑9) */
    SELECT cp.cust_id,
           cp.total_profit,
           CASE
               WHEN mm.interval_w = 0 THEN 0               -- all equal profits
               WHEN cp.total_profit = mm.max_profit
                    THEN 9                                 -- make sure max goes into last bucket
               ELSE CAST( (cp.total_profit - mm.min_profit) / mm.interval_w AS INT)
           END AS bucket_id
    FROM customer_profit AS cp
    CROSS JOIN min_max   AS mm
)

SELECT bucket_id + 1                            AS bucket_number,          -- 1‑10
       COUNT(*)                                 AS customer_count,
       MIN(total_profit)                        AS min_total_profit,
       MAX(total_profit)                        AS max_total_profit
FROM bucketed
GROUP BY bucket_id
ORDER BY bucket_number;