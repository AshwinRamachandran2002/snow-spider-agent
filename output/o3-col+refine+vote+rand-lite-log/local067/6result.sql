WITH customer_profit AS (
    SELECT 
        c.cust_id,
        SUM(s.amount_sold - s.quantity_sold * cs.unit_cost) AS profit_dec_2021
    FROM sales      AS s
    JOIN costs      AS cs ON cs.prod_id    = s.prod_id
                         AND cs.time_id    = s.time_id
                         AND cs.channel_id = s.channel_id
                         AND cs.promo_id   = s.promo_id
    JOIN customers  AS c  ON c.cust_id     = s.cust_id
    JOIN countries   AS co ON co.country_id = c.country_id
    WHERE co.country_name = 'Italy'
      AND s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
    GROUP BY c.cust_id
),
tiered AS (
    SELECT 
        cust_id,
        profit_dec_2021,
        NTILE(10) OVER (ORDER BY profit_dec_2021 DESC) AS profit_tier
    FROM customer_profit
)
SELECT 
    profit_tier,
    MAX(profit_dec_2021) AS highest_profit,
    MIN(profit_dec_2021) AS lowest_profit
FROM tiered
GROUP BY profit_tier
ORDER BY profit_tier;