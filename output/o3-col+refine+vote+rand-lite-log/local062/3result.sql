WITH italian_customer_profit AS (
    /* 1. Total December-2021 profit for each Italian customer */
    SELECT  s.cust_id,
            SUM(s.quantity_sold * (c.unit_price - c.unit_cost)) AS total_profit
    FROM        sales      AS s
    JOIN        costs      AS c
           ON   s.prod_id    = c.prod_id
          AND   s.time_id    = c.time_id
          AND   s.channel_id = c.channel_id
          AND   s.promo_id   = c.promo_id
    JOIN        times      AS t   ON s.time_id    = t.time_id
    JOIN        customers  AS cu  ON s.cust_id    = cu.cust_id
    JOIN        countries  AS co  ON cu.country_id = co.country_id
    WHERE       co.country_iso_code     = 'IT'        -- Italy only
      AND       t.calendar_year         = 2021        -- year 2021
      AND       t.calendar_month_number = 12          -- December
    GROUP BY    s.cust_id
),
limits AS (
    /* 2. Determine overall min/max profit and equal bucket width */
    SELECT  MIN(total_profit)                                         AS min_p,
            MAX(total_profit)                                         AS max_p,
            (MAX(total_profit) - MIN(total_profit)) / 10.0            AS bucket_width
    FROM    italian_customer_profit
),
bucketed AS (
    /* 3. Assign every customer to one of ten equal-width buckets */
    SELECT  icp.cust_id,
            icp.total_profit,
            CASE
                 /* all customers have identical profit → single bucket */
                 WHEN (SELECT bucket_width FROM limits) = 0 THEN 0
                 /* ensure absolute maximum lands in bucket 9 */
                 WHEN icp.total_profit = (SELECT max_p FROM limits) THEN 9
                 /* normal equal-width bucket calculation */
                 ELSE CAST((icp.total_profit - (SELECT min_p FROM limits)) /
                           (SELECT bucket_width FROM limits) AS INTEGER)
            END AS bucket_id
    FROM    italian_customer_profit AS icp
)
SELECT  bucket_id                         AS profit_bucket,
        COUNT(*)                          AS customer_count,
        MIN(total_profit)                 AS bucket_min_profit,
        MAX(total_profit)                 AS bucket_max_profit
FROM    bucketed
GROUP BY bucket_id
ORDER BY bucket_id;