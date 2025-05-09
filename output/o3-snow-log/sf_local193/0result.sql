WITH firsts AS (   -- each customer's very first purchase timestamp
    SELECT
        "customer_id",
        MIN("payment_date") AS "first_payment_date"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY "customer_id"
), agg AS (        -- lifetime sales + sales in first 7 days / 30 days
    SELECT
        p."customer_id",
        SUM(p."amount")                                                   AS "lifetime_sales",
        SUM(
            CASE
                WHEN TO_TIMESTAMP_NTZ(p."payment_date")
                     <= DATEADD(SECOND, 7*24*60*60, TO_TIMESTAMP_NTZ(f."first_payment_date"))
                THEN p."amount" ELSE 0
            END)                                                          AS "sales_first_7d",
        SUM(
            CASE
                WHEN TO_TIMESTAMP_NTZ(p."payment_date")
                     <= DATEADD(SECOND, 30*24*60*60, TO_TIMESTAMP_NTZ(f."first_payment_date"))
                THEN p."amount" ELSE 0
            END)                                                          AS "sales_first_30d"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
    JOIN firsts f
      ON p."customer_id" = f."customer_id"
    GROUP BY p."customer_id"
    HAVING SUM(p."amount") > 0        -- exclude customers with zero lifetime sales
)
SELECT
    ROUND(AVG("sales_first_7d"  / "lifetime_sales"), 4) AS "avg_pct_7d",
    ROUND(AVG("sales_first_30d" / "lifetime_sales"), 4) AS "avg_pct_30d",
    ROUND(AVG("lifetime_sales"), 2)                     AS "avg_lifetime_sales"
FROM agg;