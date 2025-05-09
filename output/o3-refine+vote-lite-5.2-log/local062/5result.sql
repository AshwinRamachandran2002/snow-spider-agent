WITH per_cust AS (          -- Italian customers' profit for December‑2021
    SELECT  c.cust_id,
            SUM( s.quantity_sold * (co.unit_price - co.unit_cost) ) AS total_profit
    FROM    customers  c
    JOIN    countries  ct   ON ct.country_id  = c.country_id
    JOIN    sales      s    ON s.cust_id      = c.cust_id
    JOIN    costs      co   ON co.prod_id     = s.prod_id
                           AND co.time_id     = s.time_id
                           AND co.channel_id  = s.channel_id
                           AND co.promo_id    = s.promo_id
    JOIN    times      t    ON t.time_id      = s.time_id
    WHERE   ct.country_name = 'Italy'
      AND   t.calendar_year = 2021
      AND   t.calendar_month_number = 12
    GROUP BY c.cust_id
),
agg AS (                     -- overall profit range
    SELECT  MIN(total_profit) AS min_profit,
            MAX(total_profit) AS max_profit
    FROM    per_cust
),
buckets AS (                 -- assign bucket 1‑10 (equal‑width)
    SELECT  p.cust_id,
            p.total_profit,
            CASE
                 WHEN (a.max_profit - a.min_profit) = 0
                 THEN 1
                 ELSE
                      1 + CAST( (p.total_profit - a.min_profit) /
                               ( (a.max_profit - a.min_profit) / 10.0 ) AS INTEGER )
            END  AS raw_bucket
    FROM    per_cust p
    CROSS JOIN agg  a
)
SELECT  CASE WHEN raw_bucket > 10 THEN 10 ELSE raw_bucket END  AS bucket_id,
        COUNT(*)                                           AS customer_count,
        MIN(total_profit)                                  AS bucket_min_profit,
        MAX(total_profit)                                  AS bucket_max_profit
FROM    buckets
GROUP BY bucket_id
ORDER BY bucket_id;