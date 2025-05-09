/* -----------------------------------------------------------
   Purpose : Average share of lifetime sales captured in the
             first 7-day and 30-day windows (exact-second based)
             plus the average total lifetime value (LTV).
   Tables  : SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
------------------------------------------------------------*/
WITH first_tx AS (      -- 1) per-customer first purchase & total LTV
    SELECT
        p."customer_id",
        MIN(p."payment_date")               AS "first_ts",
        SUM(p."amount")                     AS "total_ltv"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
    GROUP BY p."customer_id"
    HAVING SUM(p."amount") > 0             -- exclude zero-LTV customers
), win AS (            -- 2) 7-day & 30-day LTV slices for each customer
    SELECT
        f."customer_id",
        f."total_ltv",
        SUM(
            CASE
                WHEN DATEDIFF('second', f."first_ts", p."payment_date") <= 604800
                THEN p."amount" ELSE 0
            END
        ) AS "ltv_7d",
        SUM(
            CASE
                WHEN DATEDIFF('second', f."first_ts", p."payment_date") <= 2592000
                THEN p."amount" ELSE 0
            END
        ) AS "ltv_30d"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
    JOIN first_tx f
      ON p."customer_id" = f."customer_id"
    GROUP BY f."customer_id", f."total_ltv"
)                -- 3) overall averages
SELECT
    ROUND(AVG("ltv_7d"  * 100.0 / NULLIF("total_ltv", 0)), 4) AS "avg_pct_7d",
    ROUND(AVG("ltv_30d" * 100.0 / NULLIF("total_ltv", 0)), 4) AS "avg_pct_30d",
    ROUND(AVG("total_ltv"),                                   4) AS "avg_total_ltv"
FROM win;