WITH profits AS (
    /* 1.  Profit per Italian customer in December-2021 */
    SELECT  s."cust_id",
            SUM( s."quantity_sold"
                * (cst."unit_price" - cst."unit_cost") ) AS total_profit
    FROM    "sales"      AS s
    JOIN    "customers"  AS cu  ON cu."cust_id" = s."cust_id"
    JOIN    "countries"  AS co  ON co."country_id" = cu."country_id"
                               AND co."country_name" = 'Italy'
    JOIN    "costs"      AS cst ON cst."prod_id"    = s."prod_id"
                               AND cst."time_id"    = s."time_id"
                               AND cst."channel_id" = s."channel_id"
                               AND cst."promo_id"   = s."promo_id"
    WHERE   s."time_id" BETWEEN '2021-12-01' AND '2021-12-31'
    GROUP BY s."cust_id"
),
bounds AS (
    /* 2.  Overall min / max profit (needed for equal-width buckets) */
    SELECT  MIN(total_profit) AS min_p,
            MAX(total_profit) AS max_p
    FROM    profits
),
bucketed AS (
    /* 3.  Put each customer into one of 10 equal-width buckets   */
    SELECT  p."cust_id",
            p.total_profit,
            CASE
                /* ensure the absolute max value lands in the last bucket */
                WHEN (p.total_profit - b.min_p) >= (b.max_p - b.min_p) THEN 9
                ELSE CAST(
                       (p.total_profit - b.min_p)
/* width of one bucket = total range ÷ 10                                      */
                       / ((b.max_p - b.min_p) / 10.0)
                     AS INTEGER)
            END                                            AS bucket_no
    FROM    profits  AS p
    CROSS JOIN bounds AS b
)
SELECT  bucket_no,
        COUNT(*)      AS customers_in_bucket,
        MIN(total_profit)  AS min_profit_in_bucket,
        MAX(total_profit)  AS max_profit_in_bucket
FROM    bucketed
GROUP BY bucket_no
ORDER BY bucket_no;