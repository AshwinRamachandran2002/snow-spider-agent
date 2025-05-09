WITH signed_txns AS (        -- give every transaction a sign
    SELECT
        customer_id,
        DATE(txn_date)                         AS txn_date,
        CASE
            WHEN LOWER(txn_type) = 'deposit'    THEN  txn_amount
            WHEN LOWER(txn_type) = 'withdrawal' THEN -txn_amount
            ELSE 0
        END                                    AS amount
    FROM customer_transactions
),

-- list of every 1st‑of‑month contained in the data
month_starts AS (
    SELECT DISTINCT DATE(STRFTIME('%Y-%m-01', txn_date)) AS month_first
    FROM signed_txns
),

-- list of every customer that ever appeared
all_customers AS (
    SELECT DISTINCT customer_id FROM signed_txns
),

-- running balance for every customer as of the 1st of each month
cust_month_bal AS (
    SELECT
        m.month_first,
        c.customer_id,
        COALESCE((
            SELECT SUM(amount)
            FROM signed_txns s
            WHERE s.customer_id = c.customer_id
              AND s.txn_date < m.month_first          -- up‑to end of previous month
        ),0)                                         AS balance
    FROM month_starts m
    CROSS JOIN all_customers c
),

-- change negative balances to zero
clipped_bal AS (
    SELECT
        month_first,
        CASE WHEN balance < 0 THEN 0 ELSE balance END AS balance
    FROM cust_month_bal
),

-- total balance (after clipping) across all users
total_prev_month_bal AS (
    SELECT
        month_first,
        SUM(balance) AS total_balance
    FROM clipped_bal
    GROUP BY month_first
),

ordered AS (
    SELECT month_first,
           total_balance
    FROM total_prev_month_bal
    ORDER BY month_first
)

-- final result: drop the very first month (it is only the baseline)
SELECT
    STRFTIME('%Y-%m', month_first) AS month,
    total_balance
FROM ordered
WHERE month_first > (SELECT MIN(month_first) FROM ordered);