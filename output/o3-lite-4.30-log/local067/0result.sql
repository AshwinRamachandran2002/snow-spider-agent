WITH per_customer_profit AS (
    /* Profit for each Italian customer in December‑2021 */
    SELECT  cu.cust_id,
            SUM(s.amount_sold - s.quantity_sold * co.unit_cost) AS dec_profit
    FROM    customers  AS cu
    JOIN    countries  AS ctr ON ctr.country_id = cu.country_id
    JOIN    sales      AS s   ON s.cust_id     = cu.cust_id
    JOIN    times      AS t   ON t.time_id     = s.time_id
    JOIN    costs      AS co  ON co.prod_id    = s.prod_id
                              AND co.time_id   = s.time_id
                              AND co.channel_id = s.channel_id
                              AND co.promo_id   = s.promo_id
    WHERE   ctr.country_name        = 'Italy'
      AND   t.calendar_year         = 2021
      AND   t.calendar_month_number = 12
    GROUP BY cu.cust_id
),
ranked AS (
    /* Place customers into ten evenly‑sized tiers (deciles) */
    SELECT  cust_id,
            dec_profit,
            NTILE(10) OVER (ORDER BY dec_profit) AS profit_tier
    FROM    per_customer_profit
)
/* Lowest and highest profit (to 4 decimals) within each tier */
SELECT  profit_tier,
        ROUND(MIN(dec_profit),4) AS lowest_profit,
        ROUND(MAX(dec_profit),4) AS highest_profit
FROM    ranked
GROUP BY profit_tier
ORDER BY profit_tier;