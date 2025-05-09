WITH italian_customers AS (
    SELECT  c.cust_id
    FROM    customers  c
    JOIN    countries  co ON c.country_id = co.country_id
    WHERE   co.country_name = 'Italy'
),
december_profit AS (
    /*  Profit per Italian customer for December‑2021 */
    SELECT  s.cust_id,
            SUM( s.amount_sold
                 - COALESCE(s.quantity_sold * cst.unit_cost, 0) ) AS total_profit
    FROM    sales   s
    JOIN    italian_customers ic  ON ic.cust_id = s.cust_id
    JOIN    times   t             ON t.time_id  = s.time_id
    LEFT JOIN costs  cst
           ON cst.prod_id   = s.prod_id
          AND cst.time_id   = s.time_id
          AND cst.channel_id= s.channel_id
          AND cst.promo_id  = s.promo_id
    WHERE   t.calendar_month_number = 12
      AND   t.calendar_year         = 2021
    GROUP BY s.cust_id
),
tiered AS (
    /*  Divide customers into 10 equally sized tiers (1 = lowest profit) */
    SELECT  cust_id,
            total_profit,
            NTILE(10) OVER (ORDER BY total_profit) AS tier
    FROM    december_profit
)
SELECT  tier,
        ROUND(MIN(total_profit), 4) AS lowest_profit,
        ROUND(MAX(total_profit), 4) AS highest_profit
FROM    tiered
GROUP BY tier
ORDER BY tier;