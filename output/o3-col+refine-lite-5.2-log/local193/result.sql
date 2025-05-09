WITH first_purchase AS (          -- timestamp of each customer's very first payment
    SELECT "customer_id",
           MIN("payment_date") AS "first_payment_date"
    FROM   "payment"
    GROUP  BY "customer_id"
),
ltv_windows AS (                  -- LTV captured in 7‑day and 30‑day (exact 24‑hour) windows
    SELECT p."customer_id",
           SUM(p."amount")                                                             AS "total_ltv",
           SUM(CASE WHEN p."payment_date"
                        <= datetime(fp."first_payment_date", '+7 days')
                    THEN p."amount" END)                                               AS "ltv_7d",
           SUM(CASE WHEN p."payment_date"
                        <= datetime(fp."first_payment_date", '+30 days')
                    THEN p."amount" END)                                               AS "ltv_30d"
    FROM   "payment" AS p
    JOIN   first_purchase AS fp
           ON fp."customer_id" = p."customer_id"
    GROUP  BY p."customer_id"
),
pct_per_customer AS (             -- percentage of total LTV earned inside each window
    SELECT "customer_id",
           "total_ltv",
           100.0 * "ltv_7d"  / "total_ltv"                                             AS "pct_7d",
           100.0 * "ltv_30d" / "total_ltv"                                             AS "pct_30d"
    FROM   ltv_windows
    WHERE  "total_ltv" > 0                        -- exclude customers with zero lifetime sales
)
SELECT ROUND(AVG("pct_7d"), 4)   AS "avg_pct_first_7_days",
       ROUND(AVG("pct_30d"), 4)  AS "avg_pct_first_30_days",
       ROUND(AVG("total_ltv"), 4) AS "avg_total_lifetime_sales"
FROM   pct_per_customer;