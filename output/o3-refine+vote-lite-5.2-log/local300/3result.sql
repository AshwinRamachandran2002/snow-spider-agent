WITH RECURSIVE
/* 1. First and last transaction date for every customer */
cust_range AS (
    SELECT  "customer_id",
            MIN(DATE("txn_date")) AS start_date,
            MAX(DATE("txn_date")) AS end_date
    FROM    "customer_transactions"
    GROUP BY "customer_id"
),

/* 2. Net movement (deposit + , withdrawal –) for each customer/day */
txn_delta AS (
    SELECT  "customer_id",
            DATE("txn_date") AS txn_date,
            SUM(
                CASE
                    WHEN LOWER("txn_type") = 'deposit'    THEN  "txn_amount"
                    WHEN LOWER("txn_type") = 'withdrawal' THEN - "txn_amount"
                    ELSE 0
                END
            ) AS delta
    FROM    "customer_transactions"
    GROUP BY "customer_id", DATE("txn_date")
),

/* 3. Generate daily balances (carry forward, clamp at zero) */
daily_balances AS (
    /* Anchor row: each customer's first day */
    SELECT  cr."customer_id",
            cr.start_date                      AS txn_date,
            CASE
                WHEN COALESCE(td.delta,0) < 0  THEN 0
                ELSE COALESCE(td.delta,0)
            END                                AS balance
    FROM    cust_range cr
    LEFT JOIN txn_delta td
           ON td."customer_id" = cr."customer_id"
          AND td.txn_date      = cr.start_date

    UNION ALL

    /* Recursive part: next day until last transaction date */
    SELECT  db."customer_id",
            DATE(db.txn_date,'+1 day')         AS txn_date,
            CASE
                WHEN db.balance + COALESCE(td.delta,0) < 0
                THEN 0
                ELSE db.balance + COALESCE(td.delta,0)
            END                                AS balance
    FROM    daily_balances db
    JOIN    cust_range cr
           ON cr."customer_id" = db."customer_id"
    LEFT JOIN txn_delta td
           ON td."customer_id" = db."customer_id"
          AND td.txn_date      = DATE(db.txn_date,'+1 day')
    WHERE   DATE(db.txn_date,'+1 day') <= cr.end_date
),

/* 4. Highest daily balance each customer achieved within each month */
monthly_max AS (
    SELECT  "customer_id",
            STRFTIME('%Y-%m', txn_date) AS month,
            MAX(balance)                AS max_daily_balance
    FROM    daily_balances
    GROUP BY "customer_id", month
),

/* 5. Sum of those maxima across all customers for each month */
monthly_totals AS (
    SELECT  month,
            SUM(max_daily_balance)      AS total_max_balance
    FROM    monthly_max
    GROUP BY month
)

SELECT  month AS month_year,
        total_max_balance
FROM    monthly_totals
ORDER BY month;