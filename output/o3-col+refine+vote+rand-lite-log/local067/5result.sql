WITH italy_customers AS (
    SELECT c.cust_id
    FROM   customers c
    JOIN   countries co ON co.country_id = c.country_id
    WHERE  co.country_name = 'Italy'
),
dec21_sales AS (
    SELECT *
    FROM   sales
    WHERE  time_id BETWEEN '2021-12-01' AND '2021-12-31'
),
cust_profit AS (
    SELECT  s.cust_id,
            SUM(s.amount_sold - s.quantity_sold * ct.unit_cost) AS total_profit
    FROM    dec21_sales s
    JOIN    italy_customers ic       ON ic.cust_id = s.cust_id
    JOIN    costs ct                 ON ct.prod_id    = s.prod_id
                                     AND ct.time_id   = s.time_id
                                     AND ct.channel_id= s.channel_id
                                     AND ct.promo_id  = s.promo_id
    GROUP BY s.cust_id
),
tiered AS (
    SELECT  cust_id,
            total_profit,
            NTILE(10) OVER (ORDER BY total_profit) AS profit_tier
    FROM    cust_profit
)
SELECT  profit_tier,
        MIN(total_profit) AS lowest_profit,
        MAX(total_profit) AS highest_profit
FROM    tiered
GROUP BY profit_tier
ORDER BY profit_tier;