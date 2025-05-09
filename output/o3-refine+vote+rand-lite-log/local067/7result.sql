WITH italian_customers AS (
    SELECT c.cust_id
    FROM customers  AS c
    JOIN countries  AS cn
          ON cn.country_id = c.country_id
    WHERE cn.country_name = 'Italy'
),
dec_2021_sales AS (
    SELECT s.*
    FROM   sales  AS s
    WHERE  s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
      AND  s.cust_id IN (SELECT cust_id FROM italian_customers)
),
sales_with_profit AS (
    SELECT 
        s.cust_id,
        ( s.amount_sold 
          - s.quantity_sold * COALESCE(c.unit_cost,0) ) AS profit
    FROM   dec_2021_sales AS s
    LEFT JOIN costs AS c
           ON c.prod_id    = s.prod_id
          AND c.time_id    = s.time_id
          AND c.channel_id = s.channel_id
          AND c.promo_id   = s.promo_id
),
customer_profit AS (
    SELECT 
        cust_id,
        ROUND(SUM(profit),4) AS total_profit
    FROM   sales_with_profit
    GROUP  BY cust_id
),
tiered_profits AS (
    SELECT
        cust_id,
        total_profit,
        NTILE(10) OVER (ORDER BY total_profit DESC) AS profit_tier
    FROM customer_profit
)
SELECT
    profit_tier            AS tier,
    ROUND(MIN(total_profit),4) AS lowest_profit,
    ROUND(MAX(total_profit),4) AS highest_profit
FROM   tiered_profits
GROUP  BY profit_tier
ORDER  BY tier;