WITH cust_profit AS (
    /* 1.  Profit per Italian customer during Dec-2021 */
    SELECT  s."cust_id",
            SUM( (ct."unit_price" - ct."unit_cost") * s."quantity_sold") AS total_profit
    FROM        "sales"      AS s
    JOIN        "customers"  AS cu
           ON   cu."cust_id" = s."cust_id"
    JOIN        "costs"      AS ct
           ON   ct."prod_id"    = s."prod_id"
          AND   ct."time_id"    = s."time_id"
          AND   ct."channel_id" = s."channel_id"
          AND   ct."promo_id"   = s."promo_id"
    WHERE cu."country_id" = (SELECT "country_id"
                             FROM   "countries"
                             WHERE  "country_name" = 'Italy')
      AND s."time_id" BETWEEN '2021-12-01' AND '2021-12-31'
    GROUP BY s."cust_id"
),
range_vals AS (
    /* 2.  Overall min / max of those total profits */
    SELECT MIN(total_profit) AS min_p,
           MAX(total_profit) AS max_p
    FROM   cust_profit
),
bucketed AS (
    /* 3.  Put each customer into one of 10 equal-width buckets */
    SELECT cp."cust_id",
           cp.total_profit,
           CASE
               WHEN cp.total_profit = rv.max_p THEN 10                                       -- ensure max is in bucket 10
               ELSE CAST( ((cp.total_profit - rv.min_p) * 10.0) / (rv.max_p - rv.min_p)
                          AS INTEGER) + 1                                                    -- buckets 1-10
           END AS bucket
    FROM   cust_profit AS cp,
           range_vals  AS rv
)
SELECT  bucket,
        COUNT(*)               AS num_customers,
        MIN(total_profit)      AS bucket_min_profit,
        MAX(total_profit)      AS bucket_max_profit
FROM    bucketed
GROUP BY bucket
ORDER BY bucket;