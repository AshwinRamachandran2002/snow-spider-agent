WITH cust_profit AS (
    SELECT  s.cust_id,
            SUM(s.amount_sold - (c.unit_cost * s.quantity_sold)) AS profit
    FROM    sales  AS s
    JOIN    costs  AS c ON c.prod_id    = s.prod_id
                       AND c.time_id    = s.time_id
                       AND c.channel_id = s.channel_id
                       AND c.promo_id   = s.promo_id
    JOIN    times  AS t ON t.time_id = s.time_id
    WHERE   t.calendar_year         = 2021
      AND   t.calendar_month_number = 12
      AND   s.cust_id IN (SELECT cust_id
                          FROM   customers
                          WHERE  country_id IN (SELECT country_id
                                                FROM   countries
                                                WHERE  country_iso_code = 'IT'))
    GROUP BY s.cust_id
),
ranked AS (
    SELECT  cust_id,
            profit,
            NTILE(10) OVER (ORDER BY profit DESC) AS tier
    FROM    cust_profit
)
SELECT  tier,
        MAX(profit) AS highest_profit,
        MIN(profit) AS lowest_profit
FROM    ranked
GROUP BY tier
ORDER BY tier;