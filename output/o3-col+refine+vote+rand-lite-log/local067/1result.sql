WITH customer_profit AS (
    SELECT
        s.cust_id,
        SUM(s.amount_sold - co.unit_cost * s.quantity_sold) AS dec21_profit
    FROM   sales      AS s
    JOIN   costs      AS co ON  co.prod_id    = s.prod_id
                            AND co.time_id    = s.time_id
                            AND co.channel_id = s.channel_id
                            AND co.promo_id   = s.promo_id
    JOIN   customers  AS cu ON cu.cust_id     = s.cust_id
    JOIN   countries  AS c  ON c.country_id   = cu.country_id
    WHERE  c.country_iso_code = 'IT'                      -- Italy
      AND  s.time_id BETWEEN '2021-12-01' AND '2021-12-31' -- December 2021
    GROUP  BY s.cust_id
),
tiered AS (
    SELECT
        cust_id,
        dec21_profit,
        NTILE(10) OVER (ORDER BY dec21_profit) AS tier        -- ten equal-sized tiers
    FROM   customer_profit
)
SELECT
    tier                             AS profit_decile,
    MIN(dec21_profit) AS lowest_profit_in_tier,
    MAX(dec21_profit) AS highest_profit_in_tier
FROM   tiered
GROUP  BY tier
ORDER  BY tier;