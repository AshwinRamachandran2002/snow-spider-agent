WITH first_payment AS (      -- each customer’s very first payment timestamp
    SELECT  "customer_id",
            MIN("payment_date") AS "first_payment_date"
    FROM    "payment"
    GROUP BY "customer_id"
),
lifetime AS (                -- lifetime value (LTV) per customer
    SELECT  "customer_id",
            SUM("amount") AS "lifetime_sales"
    FROM    "payment"
    GROUP BY "customer_id"
),
sales_7 AS (                 -- revenue in the first 7×24h after first purchase
    SELECT  p."customer_id",
            SUM(p."amount") AS "sales_first_7_days"
    FROM    "payment" p
    JOIN    first_payment fp
           ON p."customer_id" = fp."customer_id"
          AND p."payment_date" < DATETIME(fp."first_payment_date", '+7 days')
    GROUP BY p."customer_id"
),
sales_30 AS (                -- revenue in the first 30×24h after first purchase
    SELECT  p."customer_id",
            SUM(p."amount") AS "sales_first_30_days"
    FROM    "payment" p
    JOIN    first_payment fp
           ON p."customer_id" = fp."customer_id"
          AND p."payment_date" < DATETIME(fp."first_payment_date", '+30 days')
    GROUP BY p."customer_id"
),
combined AS (                -- merge everything, keep customers with LTV > 0
    SELECT  lt."customer_id",
            lt."lifetime_sales",
            COALESCE(s7."sales_first_7_days",  0) AS "sales_first_7_days",
            COALESCE(s30."sales_first_30_days", 0) AS "sales_first_30_days"
    FROM    lifetime  lt
    LEFT JOIN sales_7  s7  ON lt."customer_id" = s7."customer_id"
    LEFT JOIN sales_30 s30 ON lt."customer_id" = s30."customer_id"
    WHERE   lt."lifetime_sales" > 0          -- exclude zero-LTV customers
)
SELECT  ROUND(AVG("lifetime_sales"),                       4) AS "avg_lifetime_sales",
        ROUND(AVG(100.0 * "sales_first_7_days"
                      / "lifetime_sales"),                 4) AS "avg_pct_first_7_days",
        ROUND(AVG(100.0 * "sales_first_30_days"
                      / "lifetime_sales"),                 4) AS "avg_pct_first_30_days"
FROM    combined;