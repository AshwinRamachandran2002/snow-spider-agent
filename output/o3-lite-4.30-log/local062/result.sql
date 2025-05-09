WITH italian_customers AS (
    SELECT c.cust_id
    FROM customers c
    JOIN countries co ON co.country_id = c.country_id
    WHERE co.country_name = 'Italy'
),
sales_dec AS (
    SELECT s.*
    FROM sales s
    JOIN italian_customers ic ON ic.cust_id = s.cust_id
    WHERE s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
),
cust_profit AS (
    SELECT  s.cust_id,
            SUM(s.quantity_sold * (ct.unit_price - ct.unit_cost)) AS total_profit
    FROM    sales_dec s
    JOIN    costs ct
           ON ct.prod_id    = s.prod_id
          AND ct.time_id    = s.time_id
          AND ct.channel_id = s.channel_id
          AND ct.promo_id   = s.promo_id
    GROUP BY s.cust_id
),
stats AS (
    SELECT MIN(total_profit) AS min_p,
           MAX(total_profit) AS max_p
    FROM   cust_profit
),
bucketed AS (
    SELECT  cp.cust_id,
            cp.total_profit,
            CASE
                WHEN (stats.max_p - stats.min_p) = 0 THEN 1
                ELSE
                    CASE
                        WHEN CAST((cp.total_profit - stats.min_p) /
                                  ((stats.max_p - stats.min_p) / 10.0) AS INTEGER) + 1 > 10
                        THEN 10
                        ELSE CAST((cp.total_profit - stats.min_p) /
                                  ((stats.max_p - stats.min_p) / 10.0) AS INTEGER) + 1
                    END
            END AS bucket_number
    FROM    cust_profit cp
    CROSS JOIN stats
)
SELECT  bucket_number,
        COUNT(*) AS customer_count,
        ROUND(MIN(total_profit),4) AS min_total_profit,
        ROUND(MAX(total_profit),4) AS max_total_profit
FROM    bucketed
GROUP BY bucket_number
ORDER BY bucket_number;