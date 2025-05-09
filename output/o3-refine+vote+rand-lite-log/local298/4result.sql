WITH txn AS (                 -- adjust sign of every transaction
    SELECT
        customer_id,
        DATE(txn_date)                                            AS txn_date,
        CASE
            WHEN LOWER(txn_type) = 'deposit' THEN  txn_amount     -- positive
            ELSE                         -1 * txn_amount          -- negative
        END                                                       AS amount
    FROM customer_transactions
),

running AS (                 -- running balance for every customer
    SELECT
        customer_id,
        txn_date,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY txn_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                         AS balance
    FROM txn
),

months AS (                  -- list of 1st‑of‑month dates present in the data
    SELECT DISTINCT
        DATE(strftime('%Y-%m-01', txn_date))                      AS month_start
    FROM txn
),

customers AS (               -- every distinct customer
    SELECT DISTINCT customer_id FROM txn
),

snapshot AS (                -- balance of every customer on each 1st‑of‑month
    SELECT
        m.month_start,
        c.customer_id,
        COALESCE((
            SELECT r.balance
            FROM   running r
            WHERE  r.customer_id = c.customer_id
               AND r.txn_date    <= m.month_start                -- up‑to date
            ORDER BY r.txn_date DESC
            LIMIT 1
        ), 0)                                                     AS balance
    FROM months     m
    CROSS JOIN customers c
),

totals AS (                  -- total (negatives truncated to 0) per month
    SELECT
        month_start,
        SUM(CASE WHEN balance < 0 THEN 0 ELSE balance END)        AS total_balance
    FROM snapshot
    GROUP BY month_start
),

shifted AS (                 -- attach every month to PREVIOUS month’s total
    SELECT
        DATE(month_start, '+1 month')                             AS month,
        total_balance                                             AS prev_month_total_balance
    FROM totals
)

SELECT
    month,
    prev_month_total_balance  AS total_balance
FROM   shifted
WHERE  month IN (SELECT month_start FROM months)                  -- drop baseline
ORDER  BY month;