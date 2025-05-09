WITH customer_profits AS (
    SELECT s.cust_id, 
           SUM(s.amount_sold - (c.unit_cost * s.quantity_sold)) AS total_profit
    FROM sales s
    JOIN costs c ON s.prod_id = c.prod_id 
                  AND s.time_id = c.time_id 
                  AND s.promo_id = c.promo_id 
                  AND s.channel_id = c.channel_id
    JOIN times t ON s.time_id = t.time_id
    WHERE s.cust_id IN (
        SELECT cust_id
        FROM customers
        WHERE country_id = (
            SELECT country_id 
            FROM countries 
            WHERE country_name = 'Italy'
        )
    )
    AND t.calendar_year = 2021 
    AND t.calendar_month_number = 12
    GROUP BY s.cust_id
),
profit_stats AS (
    SELECT MIN(total_profit) AS min_profit, MAX(total_profit) AS max_profit
    FROM customer_profits
),
intervals AS (
    SELECT (max_profit - min_profit)/10.0 AS interval_size,
           min_profit, max_profit
    FROM profit_stats
)
SELECT
    'Bucket' || bucket_number AS Profit_Bucket,
    COUNT(*) AS Number_of_Customers,
    ROUND(MAX(total_profit), 4) AS Max_Profit,
    ROUND(MIN(total_profit), 4) AS Min_Profit
FROM (
    SELECT cp.cust_id, cp.total_profit, 
        CASE 
            WHEN cp.total_profit = i.max_profit THEN 10
            ELSE CAST(((cp.total_profit - i.min_profit) / i.interval_size) AS INTEGER) + 1
        END AS bucket_number
    FROM customer_profits cp
    CROSS JOIN intervals i
) grouped_customers
GROUP BY bucket_number
ORDER BY bucket_number;