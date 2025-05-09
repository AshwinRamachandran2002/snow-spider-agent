WITH italian_customers AS (
    SELECT cu.cust_id
    FROM customers cu
    JOIN countries co
      ON cu.country_id = co.country_id
    WHERE co.country_name = 'Italy'
),
dec21_sales AS (
    SELECT s.*
    FROM sales s
    JOIN italian_customers ic
      ON s.cust_id = ic.cust_id
    WHERE s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
),
sale_profits AS (
    SELECT 
        s.cust_id,
        (s.amount_sold - COALESCE(c.unit_cost * s.quantity_sold, 0)) AS profit
    FROM dec21_sales s
    LEFT JOIN costs c
      ON c.prod_id   = s.prod_id
     AND c.time_id   = s.time_id
     AND c.promo_id  = s.promo_id
     AND c.channel_id = s.channel_id
),
customer_profits AS (
    SELECT 
        cust_id,
        ROUND(SUM(profit), 4) AS total_profit
    FROM sale_profits
    GROUP BY cust_id
),
tiered_profits AS (
    SELECT 
        cust_id,
        total_profit,
        NTILE(10) OVER (ORDER BY total_profit DESC) AS tier
    FROM customer_profits
)
SELECT
    tier,
    MAX(total_profit) AS highest_profit,
    MIN(total_profit) AS lowest_profit
FROM tiered_profits
GROUP BY tier
ORDER BY tier;