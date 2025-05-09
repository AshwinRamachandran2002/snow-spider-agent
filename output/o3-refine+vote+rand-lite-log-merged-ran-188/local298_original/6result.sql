WITH signed_txn AS (      /* give every transaction a sign */
    SELECT
        customer_id,
        DATE(txn_date)              AS txn_date,
        CASE 
            WHEN LOWER(txn_type) = 'deposit' THEN  txn_amount
            ELSE                           -1 * txn_amount
        END                            AS amount
    FROM customer_transactions
),

/* every 1st‑of‑month that appears in the data */
months AS (            
    SELECT DISTINCT DATE(txn_date,'start of month') AS month_start
    FROM customer_transactions
),

/* list of every customer */
customers AS (         
    SELECT DISTINCT customer_id
    FROM customer_transactions
),

/* running balance for every customer measured on the 1st of each month  */
balance_per_user_month AS ( 
    SELECT
        m.month_start,
        c.customer_id,
        COALESCE(SUM(t.amount),0)  AS raw_balance          -- cumulative up to (but not including) month_start
    FROM months      AS m
    CROSS JOIN customers AS c
    LEFT  JOIN signed_txn AS t
           ON  t.customer_id = c.customer_id
           AND t.txn_date   < m.month_start               -- “as of the 1st”
    GROUP BY m.month_start, c.customer_id
),

/* replace any negative balances with zero */
balance_no_negative AS (  
    SELECT
        month_start,
        customer_id,
        CASE WHEN raw_balance < 0 THEN 0 ELSE raw_balance END AS balance
    FROM balance_per_user_month
),

/* total balance across all users for each month‑start date */
total_balance_each_month AS (
    SELECT
        month_start,
        SUM(balance) AS total_balance
    FROM balance_no_negative
    GROUP BY month_start
),

/* drop the very first month since it only serves as baseline */
final AS (              
    SELECT *
    FROM total_balance_each_month
    WHERE month_start > (SELECT MIN(month_start) FROM total_balance_each_month)
)

SELECT
    STRFTIME('%Y-%m', month_start) AS month,
    total_balance
FROM final
ORDER BY month_start;