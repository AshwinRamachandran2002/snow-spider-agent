WITH txn_prepared AS (           /* 1. normalise dates & sign the amount */
    SELECT
        customer_id,
        date(txn_date)                              AS txn_date,
        date(txn_date,'start of month')             AS month_start,
        CASE 
            WHEN lower(txn_type) = 'deposit' 
                 THEN  txn_amount                   /* deposits add to balance */
            ELSE -txn_amount                        /* any other txn_type lowers balance */
        END                                         AS signed_amount
    FROM customer_transactions
),

monthly_net AS (                 /* 2. net change per customer per month  */
    SELECT
        customer_id,
        month_start,
        SUM(signed_amount)        AS net_change
    FROM txn_prepared
    GROUP BY customer_id, month_start
),

running_bal AS (                 /* 3. cumulative balance at the 1st of every month */
    SELECT
        customer_id,
        month_start,
        SUM(net_change) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                         AS balance
    FROM monthly_net
),

running_bal_nn AS (              /* 4. replace any negative balances with zero */
    SELECT
        customer_id,
        month_start,
        CASE WHEN balance < 0 THEN 0 ELSE balance END AS balance_nn
    FROM running_bal
),

tot_bal_per_month AS (           /* 5. total balance from all users each month */
    SELECT
        month_start,
        SUM(balance_nn)           AS total_balance
    FROM running_bal_nn
    GROUP BY month_start
),

shift_to_prev AS (               /* 6. shift totals forward 1 month */
    SELECT
        date(month_start,'+1 month') AS month,
        total_balance                AS total_balance_previous_month
    FROM tot_bal_per_month
)

SELECT
    month,
    total_balance_previous_month
FROM   shift_to_prev
/* 7. drop the very first calendar month (used only as baseline)        */
WHERE  month IN (SELECT DISTINCT date(txn_date,'start of month')
                 FROM customer_transactions)
ORDER BY month;