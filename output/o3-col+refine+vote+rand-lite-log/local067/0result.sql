WITH customer_profits AS (
    SELECT
        s.cust_id,
        SUM(s.amount_sold - s.quantity_sold * ct.unit_cost) AS dec2021_profit
    FROM sales      AS s
    JOIN customers  AS cu ON cu.cust_id  = s.cust_id
    JOIN countries  AS co ON co.country_id = cu.country_id
                         AND co.country_name = 'Italy'
    JOIN costs      AS ct ON ct.prod_id    = s.prod_id
                         AND ct.time_id    = s.time_id
                         AND ct.channel_id = s.channel_id
                         AND ct.promo_id   = s.promo_id
    WHERE s.time_id LIKE '2021-12%'
    GROUP BY s.cust_id
),
tiered AS (
    SELECT
        cust_id,
        dec2021_profit,
        NTILE(10) OVER (ORDER BY dec2021_profit DESC) AS profit_decile
    FROM customer_profits
)
SELECT
    profit_decile,
    MAX(dec2021_profit) AS highest_profit,
    MIN(dec2021_profit) AS lowest_profit
FROM tiered
GROUP BY profit_decile
ORDER BY profit_decile;