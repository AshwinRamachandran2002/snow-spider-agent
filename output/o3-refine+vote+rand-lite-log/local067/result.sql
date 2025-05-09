WITH italian_customers AS (
    SELECT c.cust_id
    FROM customers  c
    JOIN countries  co
          ON c.country_id = co.country_id
    WHERE co.country_iso_code = 'IT'          -- Italian customers
),
dec21_sales AS (                               -- December‑2021 sales rows
    SELECT  s.cust_id,
            (s.amount_sold - cst.unit_cost * s.quantity_sold) AS profit
    FROM    sales  s
    JOIN    italian_customers ic
           ON s.cust_id = ic.cust_id
    JOIN    costs cst
           ON s.prod_id   = cst.prod_id
          AND s.time_id   = cst.time_id
          AND s.promo_id  = cst.promo_id
          AND s.channel_id= cst.channel_id
    WHERE   s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
),
profit_per_cust AS (                           -- total profit per customer
    SELECT  cust_id,
            ROUND(SUM(profit),4) AS total_profit
    FROM    dec21_sales
    GROUP BY cust_id
),
tiered AS (                                    -- split into 10 equal tiers
    SELECT  cust_id,
            total_profit,
            NTILE(10) OVER (ORDER BY total_profit DESC) AS tier
    FROM    profit_per_cust
)
SELECT  tier,
        ROUND(MAX(total_profit),4) AS highest_profit,
        ROUND(MIN(total_profit),4) AS lowest_profit
FROM    tiered
GROUP BY tier
ORDER BY tier;