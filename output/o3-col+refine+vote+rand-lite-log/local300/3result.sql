WITH
-- 1.  Determine each customer’s first and last transaction dates
cust_span AS (
    SELECT  "customer_id",
            MIN( DATE("txn_date") ) AS first_day,
            MAX( DATE("txn_date") ) AS last_day
    FROM    "customer_transactions"
    GROUP BY "customer_id"
),

-- 2.  Recursively build every calendar day for every customer,
--     work out that day’s net cash-flow,
--     then roll the balance forward while flooring negatives to 0
daily_balances AS (
    /* --- anchor row : first day for every customer ----------------- */
    SELECT  
        c."customer_id",
        c.first_day             AS txn_day,

        /* net cash-flow on the first day ( +deposit , –everything else ) */
        COALESCE( (
            SELECT  SUM( CASE WHEN ct."txn_type" = 'deposit' 
                              THEN  ct."txn_amount"         /* +ve  */
                              ELSE -ct."txn_amount"         /* –ve  */
                         END )
            FROM    "customer_transactions" ct
            WHERE   ct."customer_id" = c."customer_id"
            AND     DATE(ct."txn_date")  = c.first_day
        ), 0)                      AS net_amt,

        /* day-end balance (never below zero) */
        MAX( 0,
             COALESCE( (
                 SELECT  SUM( CASE WHEN ct."txn_type" = 'deposit'
                                   THEN  ct."txn_amount"
                                   ELSE -ct."txn_amount"
                              END )
                 FROM    "customer_transactions" ct
                 WHERE   ct."customer_id" = c."customer_id"
                 AND     DATE(ct."txn_date") = c.first_day
             ), 0)
        )                           AS balance
    FROM    cust_span  c

    UNION ALL

    /* --- recursive rows : every next calendar day ------------------ */
    SELECT
        d."customer_id",
        DATE(d.txn_day,'+1 day')    AS txn_day,

        /* net cash-flow on the next day */
        COALESCE( (
            SELECT  SUM( CASE WHEN ct."txn_type" = 'deposit'
                              THEN  ct."txn_amount"
                              ELSE -ct."txn_amount"
                         END )
            FROM    "customer_transactions" ct
            WHERE   ct."customer_id" = d."customer_id"
            AND     DATE(ct."txn_date") = DATE(d.txn_day,'+1 day')
        ), 0)                       AS net_amt,

        /* running balance carried forward (floored at zero) */
        MAX( 0,
             d.balance +
             COALESCE( (
                 SELECT  SUM( CASE WHEN ct."txn_type" = 'deposit'
                                   THEN  ct."txn_amount"
                                   ELSE -ct."txn_amount"
                              END )
                 FROM    "customer_transactions" ct
                 WHERE   ct."customer_id" = d."customer_id"
                 AND     DATE(ct."txn_date") = DATE(d.txn_day,'+1 day')
             ), 0)
        )                           AS balance
    FROM    daily_balances d
    JOIN    cust_span      c
        ON  c."customer_id" = d."customer_id"
    /* stop once we have reached the customer’s last transaction date */
    WHERE   DATE(d.txn_day) < c.last_day
),

-- 3.  For every customer-month, keep their highest daily balance
monthly_peaks AS (
    SELECT  "customer_id",
            STRFTIME('%Y-%m', txn_day)      AS month,
            MAX(balance)                    AS max_daily_balance
    FROM    daily_balances
    GROUP BY "customer_id", month
)

-- 4.  Sum those peaks across all customers to get the final result
SELECT  month,
        SUM(max_daily_balance)  AS total_monthly_max_balances
FROM    monthly_peaks
GROUP BY month
ORDER BY month;