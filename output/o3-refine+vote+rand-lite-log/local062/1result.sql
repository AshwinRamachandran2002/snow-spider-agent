WITH italy_customers AS (
    -- all customers whose country is Italy
    SELECT c.cust_id
    FROM   customers  c
    JOIN   countries  ct
           ON c.country_id = ct.country_id
    WHERE  ct.country_iso_code = 'IT'
),
dec21_profit_per_cust AS (
    -- total December‑2021 profit (unit_price‑unit_cost)*qty for every Italian customer
    SELECT  s.cust_id,
            SUM(s.quantity_sold * (co.unit_price - co.unit_cost)) AS total_profit
    FROM    sales   s
    JOIN    italy_customers ic  ON ic.cust_id = s.cust_id
    JOIN    times  t            ON t.time_id   = s.time_id
    JOIN    costs  co           ON co.prod_id  = s.prod_id      -- align cost row
                               AND co.time_id  = s.time_id
                               AND co.channel_id = s.channel_id
    WHERE   t.calendar_year        = 2021
      AND   t.calendar_month_number = 12
    GROUP BY s.cust_id
),
bounds AS (
    -- overall min / max profit in the month
    SELECT MIN(total_profit) AS min_profit,
           MAX(total_profit) AS max_profit
    FROM   dec21_profit_per_cust
),
bucketed AS (
    -- put every customer into one of 10 equal‑width buckets (0‑9)
    SELECT  p.cust_id,
            p.total_profit,
            CASE
                 WHEN b.max_profit = b.min_profit                THEN 0                -- all equal
                 WHEN p.total_profit = b.max_profit              THEN 9                -- rightmost edge
                 ELSE CAST( (p.total_profit - b.min_profit) /
                           ((b.max_profit - b.min_profit)/10.0)  AS INTEGER)
            END AS bucket
    FROM    dec21_profit_per_cust p
    CROSS JOIN bounds b
)
SELECT  bucket + 1                      AS bucket_number,       -- 1‑10
        COUNT(*)                        AS customer_count,
        MIN(total_profit)               AS bucket_min_profit,
        MAX(total_profit)               AS bucket_max_profit
FROM    bucketed
GROUP BY bucket
ORDER BY bucket;