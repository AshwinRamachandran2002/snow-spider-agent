WITH profits AS (   -- total December-2021 profit per Italian customer
    SELECT  s.cust_id,
            SUM( s.quantity_sold * (c.unit_price - c.unit_cost) ) AS total_profit
    FROM    sales      AS s
    JOIN    costs      AS c   ON  s.prod_id    = c.prod_id
                              AND s.time_id    = c.time_id
                              AND s.channel_id = c.channel_id
                              AND s.promo_id   = c.promo_id
    JOIN    customers  AS cu  ON  s.cust_id    = cu.cust_id
    WHERE   cu.country_id = ( SELECT country_id
                              FROM   countries
                              WHERE  country_name = 'Italy' )
      AND   s.time_id IN ( SELECT time_id
                           FROM   times
                           WHERE  calendar_year        = 2021
                             AND  calendar_month_number = 12 )
    GROUP BY s.cust_id
),
bounds AS (          -- overall range and interval size
    SELECT  MIN(total_profit)                                   AS min_profit,
            MAX(total_profit)                                   AS max_profit,
            (MAX(total_profit) - MIN(total_profit)) / 10.0      AS interval_size
    FROM    profits
),
bucketed AS (        -- assign each customer to one of the 10 equal-width buckets
    SELECT  p.cust_id,
            p.total_profit,
            CASE
                WHEN b.interval_size = 0              THEN 1
                WHEN p.total_profit = b.max_profit    THEN 10
                ELSE CAST( (p.total_profit - b.min_profit) / b.interval_size AS INTEGER ) + 1
            END                                        AS profit_bucket
    FROM    profits p
    CROSS JOIN bounds b
)
SELECT  profit_bucket,
        COUNT(*)        AS num_customers,
        MIN(total_profit)  AS min_profit_in_bucket,
        MAX(total_profit)  AS max_profit_in_bucket
FROM    bucketed
GROUP BY profit_bucket
ORDER BY profit_bucket;