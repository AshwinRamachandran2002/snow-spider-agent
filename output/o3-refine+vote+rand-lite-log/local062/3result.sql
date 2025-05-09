WITH italian_customers AS (
    SELECT c.cust_id
    FROM customers  c
    JOIN countries  co ON co.country_id = c.country_id
    WHERE co.country_name = 'Italy'          -- Italian customers
),

-- sales made in December‑2021
dec_sales AS (
    SELECT s.*
    FROM sales  s
    JOIN times  t ON t.time_id = s.time_id
    WHERE t.calendar_year  = 2021
      AND t.calendar_month_number = 12
),

-- profit for every (Italian) sales row in that month
sales_profit AS (
    SELECT ds.cust_id,
           ds.quantity_sold * (ct.unit_price - ct.unit_cost) AS profit
    FROM dec_sales ds
    JOIN costs ct
      ON ct.prod_id   = ds.prod_id
     AND ct.time_id   = ds.time_id
     AND ct.promo_id  = ds.promo_id
     AND ct.channel_id= ds.channel_id
    WHERE ds.cust_id IN (SELECT cust_id FROM italian_customers)
),

-- total monthly profit per Italian customer (zero if no purchase)
profit_per_customer AS (
    SELECT ic.cust_id,
           COALESCE(SUM(sp.profit),0) AS total_profit
    FROM italian_customers ic
    LEFT JOIN sales_profit sp ON sp.cust_id = ic.cust_id
    GROUP BY ic.cust_id
),

-- overall range and bucket width
stats AS (
    SELECT  MIN(total_profit)                         AS min_profit,
            MAX(total_profit)                         AS max_profit,
            (MAX(total_profit) - MIN(total_profit)) / 10.0 AS width
    FROM profit_per_customer
),

-- assign each customer to one of ten equal‑width buckets
bucketed AS (
    SELECT pc.cust_id,
           pc.total_profit,
           CASE
               WHEN s.width = 0 THEN 1
               ELSE
                   CASE
                       WHEN CAST((pc.total_profit - s.min_profit)/s.width AS INTEGER) + 1 > 10
                       THEN 10
                       ELSE CAST((pc.total_profit - s.min_profit)/s.width AS INTEGER) + 1
                   END
           END AS bucket
    FROM profit_per_customer pc
    CROSS JOIN stats s
)

SELECT  bucket,
        COUNT(*)                 AS num_customers,
        MIN(total_profit)        AS min_total_profit,
        MAX(total_profit)        AS max_total_profit
FROM    bucketed
GROUP BY bucket
ORDER BY bucket;