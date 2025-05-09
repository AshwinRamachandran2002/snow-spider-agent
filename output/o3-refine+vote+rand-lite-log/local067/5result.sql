WITH italian_customers AS (                       -- all customers that live in Italy
    SELECT c.cust_id
    FROM   customers  c
    JOIN   countries  co ON c.country_id = co.country_id
    WHERE  co.country_name = 'Italy'
),
cost_per_item AS (                                -- one cost per product‑day
    SELECT prod_id,
           time_id,
           AVG(unit_cost) AS unit_cost            -- average in case several rows exist
    FROM   costs
    GROUP  BY prod_id, time_id
),
cust_dec21_profit AS (                            -- total December‑2021 profit per customer
    SELECT  s.cust_id,
            SUM( s.amount_sold
                  - IFNULL(cpi.unit_cost,0) * s.quantity_sold ) AS profit
    FROM   sales        s
    JOIN   italian_customers ic  ON s.cust_id = ic.cust_id
    JOIN   times         t       ON s.time_id = t.time_id
    LEFT   JOIN cost_per_item cpi ON cpi.prod_id = s.prod_id
                                  AND cpi.time_id = s.time_id
    WHERE  t.calendar_year        = 2021
      AND  t.calendar_month_number = 12          -- December 2021
    GROUP  BY s.cust_id
),
deciles AS (                                      -- split profits into 10 even tiers
    SELECT cust_id,
           profit,
           NTILE(10) OVER (ORDER BY profit) AS tier
    FROM   cust_dec21_profit
)
SELECT  tier,
        MIN(profit) AS lowest_profit,
        MAX(profit) AS highest_profit
FROM    deciles
GROUP   BY tier
ORDER   BY tier;