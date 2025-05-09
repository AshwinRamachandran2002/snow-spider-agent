/* -----------------------------------------------------------
   Monthly total balance (as at the 1st of every month), where
   the balance is the cumulative sum of all customers’ signed
   transactions up to (and including) the last day of the
   previous month.  Negative totals are set to zero and the very
   first month is omitted from the output.
   ----------------------------------------------------------- */
WITH signed_txns AS (
    /* give every transaction a sign:
       + for deposits / credits, − for withdrawals / debits       */
    SELECT
        customer_id,
        DATE(txn_date)                           AS txn_date,
        CASE
            WHEN LOWER(txn_type) IN ('deposit','credit','receive')          THEN  txn_amount
            WHEN LOWER(txn_type) IN ('withdrawal','debit','purchase','payment','spend')  
                                                                            THEN -txn_amount
            ELSE txn_amount   -- fall‑back (treat as positive)
        END                                      AS amount
    FROM customer_transactions
),
balance_as_of_next_month AS (
    /* push every txn to the 1st of the following month;
       summing now gives the balance as at that date            */
    SELECT
        DATE(txn_date, 'start of month', '+1 month') AS month_start,
        SUM(amount)                                  AS raw_balance
    FROM signed_txns
    GROUP BY month_start
),
cleaned_balances AS (
    /* replace any negative totals with zero                    */
    SELECT
        month_start,
        CASE WHEN raw_balance < 0 THEN 0 ELSE raw_balance END AS total_balance
    FROM balance_as_of_next_month
),
final_output AS (
    /* drop the very first month (used only as a baseline)      */
    SELECT *
    FROM   cleaned_balances
    WHERE  month_start > (SELECT MIN(month_start) FROM cleaned_balances)
)
SELECT
    month_start  AS month,          -- e.g. 2020-02-01
    total_balance                   -- cumulative balance (≥ 0)
FROM final_output
ORDER BY month_start;