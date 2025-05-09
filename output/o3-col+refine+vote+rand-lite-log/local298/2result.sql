WITH monthly_change AS (
    /* 1.  Turn every transaction into a signed amount
          and anchor it to the 1-st day of the NEXT month          */
    SELECT  customer_id,
            DATE(DATE(txn_date,'+1 month','start of month')) AS month_start,
            CASE WHEN txn_type = 'deposit'
                 THEN  txn_amount
                 ELSE -1 * txn_amount
            END AS signed_amount
    FROM customer_transactions
),
summed AS (
    /* 2.  Net change for every customer in every month            */
    SELECT  customer_id,
            month_start,
            SUM(signed_amount) AS chg
    FROM   monthly_change
    GROUP  BY customer_id, month_start
),
running AS (
    /* 3.  Running balance per customer (as-of each 1-st of month) */
    SELECT  customer_id,
            month_start,
            SUM(chg) OVER (PARTITION BY customer_id
                           ORDER BY month_start) AS bal
    FROM   summed
),
positive_bal AS (
    /* 4.  Replace any negative balances with zero                 */
    SELECT  month_start,
            CASE WHEN bal < 0 THEN 0 ELSE bal END AS pos_bal
    FROM   running
),
month_totals AS (
    /* 5.  Total balance across ALL customers, month by month      */
    SELECT  month_start,
            SUM(pos_bal) AS total_balance
    FROM   positive_bal
    GROUP  BY month_start
),
prev_balance AS (
    /* 6.  Bring forward each month’s total to the NEXT month      */
    SELECT  month_start,
            LAG(total_balance) OVER (ORDER BY month_start) AS prev_month_balance
    FROM   month_totals
)
SELECT  month_start       AS month_first_day,
        prev_month_balance AS total_balance
FROM    prev_balance
WHERE   prev_month_balance IS NOT NULL        -- drop the baseline month
ORDER BY month_start;