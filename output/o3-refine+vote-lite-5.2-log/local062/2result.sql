WITH italian_customers AS (
    SELECT c.cust_id
    FROM customers      AS c
    JOIN countries      AS co ON c.country_id = co.country_id
    WHERE co.country_name = 'Italy'
),
dec_2021_sales AS (
    SELECT s.*
    FROM   sales  AS s
    JOIN   times  AS t ON s.time_id = t.time_id
    WHERE  t.calendar_month_number = 12
      AND  t.calendar_year         = 2021
),
customer_month_profit AS (
    /* profit = quantity_sold * (unit_price - unit_cost) */
    SELECT  ic.cust_id,
            SUM(s.quantity_sold * (ct.unit_price - ct.unit_cost)) AS total_profit
    FROM    italian_customers   AS ic
    JOIN    dec_2021_sales      AS s  ON s.cust_id = ic.cust_id
    JOIN    costs               AS ct ON ct.prod_id   = s.prod_id
                                      AND ct.time_id  = s.time_id
                                      AND ct.channel_id = s.channel_id
                                      AND ct.promo_id = s.promo_id
    GROUP BY ic.cust_id
),
profit_stats AS (
    SELECT  MIN(total_profit)                                AS min_profit,
            MAX(total_profit)                                AS max_profit,
            MAX(total_profit) - MIN(total_profit)            AS range_profit
    FROM    customer_month_profit
),
bucketed_profits AS (
    SELECT  cmp.cust_id,
            cmp.total_profit,
            CASE
                 /* if all profits are equal, put everyone into bucket 1 */
                 WHEN ps.range_profit = 0 THEN 1
                 /* ensure the absolute maximum falls into bucket 10 */
                 WHEN cmp.total_profit = ps.max_profit THEN 10
                 /* otherwise distribute into 10 equal‑width buckets */
                 ELSE CAST( ((cmp.total_profit - ps.min_profit) * 10.0 / ps.range_profit) AS INTEGER ) + 1
            END                                                AS bucket
    FROM    customer_month_profit  AS cmp
    CROSS JOIN profit_stats        AS ps
)
SELECT  bucket                                    AS profit_bucket,
        COUNT(*)                                  AS customer_count,
        MIN(total_profit)                         AS bucket_min_profit,
        MAX(total_profit)                         AS bucket_max_profit
FROM    bucketed_profits
GROUP BY bucket
ORDER BY bucket;