SELECT
    profit_tier,
    MIN(total_profit) AS lowest_profit,
    MAX(total_profit) AS highest_profit
FROM (
    SELECT
        cust_id,
        ROUND(total_profit_raw, 4) AS total_profit,
        NTILE(10) OVER (ORDER BY total_profit_raw DESC) AS profit_tier
    FROM (
        SELECT
            s.cust_id,
            SUM(s.amount_sold - s.quantity_sold * cs.unit_cost) AS total_profit_raw
        FROM sales      AS s
        JOIN customers  AS cu ON cu.cust_id   = s.cust_id
        JOIN countries  AS co ON co.country_id = cu.country_id
        JOIN times      AS t  ON t.time_id    = s.time_id
        JOIN costs      AS cs ON cs.prod_id   = s.prod_id
                               AND cs.time_id = s.time_id
                               AND cs.channel_id = s.channel_id
                               AND cs.promo_id   = s.promo_id
        WHERE co.country_name         = 'Italy'
          AND t.calendar_month_number = 12
          AND t.calendar_year         = 2021
        GROUP BY s.cust_id
    )
)
GROUP BY profit_tier
ORDER BY profit_tier;