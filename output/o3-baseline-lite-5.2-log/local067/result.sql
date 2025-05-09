WITH italian_customers AS (
    SELECT c.cust_id
    FROM customers AS c
    JOIN countries AS co
          ON c.country_id = co.country_id
    WHERE co.country_iso_code = 'IT'
       OR co.country_name      = 'Italy'
),
dec2021_sales AS (
    SELECT s.*
    FROM   sales  AS s
    JOIN   times  AS t
           ON s.time_id = t.time_id
    WHERE  t.calendar_year        = 2021
      AND  t.calendar_month_number = 12
),
sales_costs AS (
    SELECT s.cust_id,
           s.amount_sold,
           s.quantity_sold,
           COALESCE(ct.unit_cost,0) AS unit_cost
    FROM   dec2021_sales AS s
    JOIN   italian_customers AS ic
           ON s.cust_id = ic.cust_id
    LEFT JOIN costs AS ct
           ON ct.prod_id    = s.prod_id
          AND ct.time_id    = s.time_id
          AND ct.channel_id = s.channel_id
          AND ct.promo_id   = s.promo_id
),
customer_profit AS (
    SELECT cust_id,
           SUM(amount_sold - quantity_sold*unit_cost) AS total_profit
    FROM   sales_costs
    GROUP  BY cust_id
),
tiering AS (
    SELECT cust_id,
           ROUND(total_profit,4) AS total_profit,
           NTILE(10) OVER(ORDER BY total_profit DESC) AS tier
    FROM   customer_profit
)
SELECT tier,
       ROUND(MIN(total_profit),4) AS lowest_profit,
       ROUND(MAX(total_profit),4) AS highest_profit
FROM   tiering
GROUP  BY tier
ORDER BY tier;