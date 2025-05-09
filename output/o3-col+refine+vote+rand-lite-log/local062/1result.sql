WITH cust_profit AS (
    /* 1.  Italian customers’ total profit in Dec-2021 */
    SELECT  s."cust_id",
            SUM( s."quantity_sold"
                * (cst."unit_price" - cst."unit_cost") )  AS total_profit
    FROM   "sales"      AS s
    JOIN   "costs"      AS cst
           ON  s."prod_id"    = cst."prod_id"
           AND s."time_id"    = cst."time_id"
           AND s."promo_id"   = cst."promo_id"
           AND s."channel_id" = cst."channel_id"
    JOIN   "customers"  AS cu  ON s."cust_id" = cu."cust_id"
    JOIN   "countries"  AS co  ON cu."country_id" = co."country_id"
    JOIN   "times"      AS t   ON s."time_id" = t."time_id"
    WHERE  co."country_name"          = 'Italy'
      AND  t."calendar_month_number"  = 12
      AND  t."calendar_year"          = 2021
    GROUP BY s."cust_id"
),
stats AS (
    /* 2.  Overall range and equal-width bucket size */
    SELECT  MIN(total_profit)                                AS min_p,
            MAX(total_profit)                                AS max_p,
            (MAX(total_profit) - MIN(total_profit)) / 10.0   AS bucket_size
    FROM   cust_profit
),
bucketed AS (
    /* 3.  Assign each customer to one of 10 buckets (0-9) */
    SELECT  cp."cust_id",
            cp.total_profit,
            CASE
                 WHEN cp.total_profit = st.max_p
                 THEN 9                       -- ensure max falls in top bucket
                 ELSE CAST( (cp.total_profit - st.min_p) / st.bucket_size AS INTEGER )
            END  AS bucket_id
    FROM   cust_profit AS cp
    CROSS  JOIN stats  AS st
)
SELECT  b.bucket_id,
        ROUND(MIN(b.total_profit),4)  AS bucket_min_profit,
        ROUND(MAX(b.total_profit),4)  AS bucket_max_profit,
        COUNT(*)                      AS customers_in_bucket
FROM    bucketed AS b
GROUP BY b.bucket_id
ORDER BY b.bucket_id;