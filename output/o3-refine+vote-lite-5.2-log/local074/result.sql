WITH RECURSIVE
    /* 1. overall first and last transaction dates */
    date_bounds AS (
        SELECT
            date(min("txn_date")) AS min_date,
            date(max("txn_date")) AS max_date
        FROM "customer_transactions"
    ),

    /* 2. continuous list of month starts within date range */
    months(month_start) AS (
        SELECT date(min_date,'start of month')
        FROM   date_bounds
        UNION ALL
        SELECT date(month_start,'+1 month')
        FROM   months, date_bounds
        WHERE  month_start < date(max_date,'start of month')
    ),

    /* 3. every customer ever seen */
    customers AS (
        SELECT DISTINCT "customer_id"
        FROM   "customer_transactions"
    ),

    /* 4. complete customer‑month grid */
    customer_months AS (
        SELECT
            c."customer_id",
            m.month_start
        FROM  customers c
        CROSS JOIN months m
    ),

    /* 5. net change per customer per month */
    monthly_change AS (
        SELECT
            cm."customer_id",
            cm.month_start,
            COALESCE(
                SUM(
                    CASE
                        WHEN LOWER(ct."txn_type") = 'deposit'    THEN  ct."txn_amount"
                        WHEN LOWER(ct."txn_type") = 'withdrawal' THEN -ct."txn_amount"
                        ELSE 0
                    END
                ), 0
            ) AS monthly_change
        FROM  customer_months cm
        LEFT JOIN "customer_transactions" ct
               ON ct."customer_id" = cm."customer_id"
              AND date(ct."txn_date",'start of month') = cm.month_start
        GROUP BY cm."customer_id", cm.month_start
    ),

    /* 6. running (closing) balance */
    balances AS (
        SELECT
            "customer_id",
            strftime('%Y-%m', month_start)            AS month_year,
            monthly_change,
            SUM(monthly_change) OVER (
                PARTITION BY "customer_id"
                ORDER BY     month_start
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )                                         AS closing_balance
        FROM monthly_change
    )

/* 7. final ordered result */
SELECT *
FROM   balances
ORDER  BY "customer_id", month_year;