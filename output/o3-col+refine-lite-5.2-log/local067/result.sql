WITH italian_country AS (
    SELECT country_id
    FROM   countries
    WHERE  country_name = 'Italy'
),
customer_profit AS (
    SELECT  s.cust_id,
            SUM( s.amount_sold
                 - COALESCE(c.unit_cost,0) * s.quantity_sold ) AS profit
    FROM   sales      AS s
    JOIN   customers  AS cu ON cu.cust_id = s.cust_id
    JOIN   italian_country ic ON ic.country_id = cu.country_id
    JOIN   times      AS t  ON t.time_id  = s.time_id
    LEFT   JOIN costs AS c
           ON  c.prod_id    = s.prod_id
           AND c.time_id    = s.time_id
           AND c.channel_id = s.channel_id
           AND c.promo_id   = s.promo_id
    WHERE  t.calendar_month_number = 12
      AND  t.calendar_year         = 2021
    GROUP BY s.cust_id
),
tiered_profits AS (
    SELECT  cust_id,
            profit,
            NTILE(10) OVER (ORDER BY profit) AS tier
    FROM    customer_profit
)
SELECT  tier,
        ROUND(MIN(profit),4)  AS lowest_profit,
        ROUND(MAX(profit),4)  AS highest_profit
FROM    tiered_profits
GROUP BY tier
ORDER BY tier;