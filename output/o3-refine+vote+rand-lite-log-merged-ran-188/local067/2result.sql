WITH italian_customer_profits AS (
    /* 1.  Profit earned in Dec‑2021 for each Italian customer */
    SELECT
        s.cust_id,
        SUM(s.amount_sold - s.quantity_sold * c.unit_cost) AS total_profit
    FROM   sales      AS s
    JOIN   customers  AS cu ON cu.cust_id   = s.cust_id
    JOIN   countries  AS co ON co.country_id = cu.country_id
    JOIN   costs      AS c  ON c.prod_id    = s.prod_id
                           AND c.time_id    = s.time_id
                           AND c.promo_id   = s.promo_id
                           AND c.channel_id = s.channel_id
    WHERE  (co.country_name = 'Italy' OR co.country_iso_code = 'IT')
      AND  s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
    GROUP  BY s.cust_id
),
tiered_profits AS (
    /* 2.  Divide customers into 10 equal‑sized tiers by profit */
    SELECT
        cust_id,
        total_profit,
        NTILE(10) OVER (ORDER BY total_profit DESC) AS tier
    FROM   italian_customer_profits
)
SELECT   tier,
         MAX(total_profit) AS highest_profit,
         MIN(total_profit) AS lowest_profit
FROM     tiered_profits
GROUP BY tier
ORDER BY tier;