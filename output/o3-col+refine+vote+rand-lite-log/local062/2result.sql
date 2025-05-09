WITH customer_monthly_profit AS (           -- 1.  total Dec-2021 profit for every Italian customer
    SELECT  s."cust_id",
            SUM( s."quantity_sold"
                * (ct."unit_price" - ct."unit_cost") )            AS total_profit
    FROM    "sales"      AS s
    JOIN    "costs"      AS ct
           ON ct."prod_id"   = s."prod_id"
          AND ct."time_id"   = s."time_id"
          AND ct."promo_id"  = s."promo_id"
          AND ct."channel_id"= s."channel_id"
    JOIN    "customers"  AS c   ON s."cust_id"  = c."cust_id"
    JOIN    "countries"  AS co  ON c."country_id" = co."country_id"
    JOIN    "times"      AS t   ON s."time_id"   = t."time_id"
    WHERE   co."country_name"        = 'Italy'
      AND   t."calendar_year"        = 2021
      AND   t."calendar_month_number" = 12
    GROUP BY s."cust_id"
),
bounds AS (                               -- 2.  overall min, max and equal interval width
    SELECT  MIN(total_profit)                         AS mn,
            MAX(total_profit)                         AS mx,
           (MAX(total_profit) - MIN(total_profit)) / 10.0 AS step
    FROM    customer_monthly_profit
),
binned AS (                               -- 3.  put each customer into one of ten buckets
    SELECT  cmp."cust_id",
            cmp.total_profit,
            CASE
               WHEN b.step = 0 THEN 1                           -- all profits identical
               ELSE
                   CASE                                         -- cap at 10 so we never exceed
                       WHEN 1 + CAST( FLOOR( (cmp.total_profit - b.mn) / b.step ) AS INTEGER ) >= 10
                       THEN 10
                       ELSE 1 + CAST( FLOOR( (cmp.total_profit - b.mn) / b.step ) AS INTEGER )
                   END
            END AS bucket
    FROM    customer_monthly_profit AS cmp
    CROSS JOIN bounds               AS b
)
SELECT  bucket,
        COUNT(*)            AS num_customers,
        MIN(total_profit)   AS bucket_min_profit,
        MAX(total_profit)   AS bucket_max_profit
FROM    binned
GROUP  BY bucket
ORDER  BY bucket;