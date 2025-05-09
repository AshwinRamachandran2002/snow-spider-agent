WITH italian_customer_profit AS (
    SELECT
        s.cust_id,
        SUM(s.amount_sold - s.quantity_sold * c.unit_cost) AS total_profit
    FROM sales     AS s
    JOIN costs     AS c  ON s.prod_id   = c.prod_id
                        AND s.time_id   = c.time_id
                        AND s.promo_id  = c.promo_id
                        AND s.channel_id= c.channel_id
    JOIN times     AS t  ON s.time_id   = t.time_id
    JOIN customers AS cu ON s.cust_id   = cu.cust_id
    JOIN countries AS co ON cu.country_id = co.country_id
    WHERE co.country_name        = 'Italy'
      AND t.calendar_month_number = 12        -- December
      AND t.calendar_year         = 2021
    GROUP BY s.cust_id
),
profit_with_tier AS (
    SELECT
        cust_id,
        total_profit,
        NTILE(10) OVER (ORDER BY total_profit) AS tier
    FROM italian_customer_profit
)
SELECT
    tier,
    MIN(total_profit) AS lowest_profit,
    MAX(total_profit) AS highest_profit
FROM profit_with_tier
GROUP BY tier
ORDER BY tier;