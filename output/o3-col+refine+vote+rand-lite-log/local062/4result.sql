WITH italian_profits AS (
    -- 1)  Total December-2021 profit per Italian customer
    SELECT  s.cust_id,
            SUM( s.quantity_sold * (co.unit_price - co.unit_cost) ) AS total_profit
    FROM          sales      AS s
    JOIN          customers  AS cu  ON cu.cust_id = s.cust_id
    JOIN          countries  AS ct  ON ct.country_id = cu.country_id
    JOIN          costs      AS co  ON co.prod_id    = s.prod_id
                                   AND co.time_id    = s.time_id
                                   AND co.channel_id = s.channel_id
                                   AND co.promo_id   = s.promo_id
    WHERE ct.country_name = 'Italy'
      AND s.time_id LIKE '2021-12%'          -- December-2021 only
    GROUP BY s.cust_id
),
minmax AS (
    -- 2)  Overall min / max customer profit
    SELECT MIN(total_profit) AS min_p,
           MAX(total_profit) AS max_p
    FROM   italian_profits
),
bucketed AS (
    -- 3)  Assign each customer to one of ten equal-width buckets (0-9)
    SELECT ip.cust_id,
           ip.total_profit,
           CASE 
               WHEN CAST(
                        (ip.total_profit - mm.min_p) 
                        / ((mm.max_p - mm.min_p) / 10.0) 
                        AS INTEGER
                    ) = 10            -- make sure the max value lands in bucket 9
               THEN 9
               ELSE CAST(
                        (ip.total_profit - mm.min_p) 
                        / ((mm.max_p - mm.min_p) / 10.0) 
                        AS INTEGER
                    )
           END AS bucket
    FROM   italian_profits AS ip
    CROSS JOIN minmax AS mm
)
-- 4)  Final report: customers per bucket + profit range in each bucket
SELECT  bucket,
        COUNT(cust_id)              AS num_customers,
        MIN(total_profit)           AS min_profit,
        MAX(total_profit)           AS max_profit
FROM    bucketed
GROUP BY bucket
ORDER BY bucket;