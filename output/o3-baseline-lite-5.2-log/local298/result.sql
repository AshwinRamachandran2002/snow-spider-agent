WITH txns AS (      -- sign each transaction (+ for deposits, - for any other type)
    SELECT
        customer_id,
        DATE("txn_date")                    AS txn_date,
        CASE 
            WHEN LOWER("txn_type") = 'deposit' THEN txn_amount
            ELSE -txn_amount
        END                                AS signed_amount
    FROM customer_transactions
),
monthly_net AS (    -- net movement per customer per month
    SELECT
        customer_id,
        DATE(STRFTIME('%Y-%m-01', txn_date)) AS month_first_day,
        SUM(signed_amount)                    AS net_amount
    FROM txns
    GROUP BY customer_id,
             month_first_day
),
cum_bal AS (        -- cumulative balance at the end of each month
    SELECT
        customer_id,
        month_first_day,
        SUM(net_amount) OVER (PARTITION BY customer_id
                              ORDER BY month_first_day) AS cum_balance
    FROM monthly_net
),
prev_month_bal AS ( -- balance at the end of the PREVIOUS month
    SELECT
        customer_id,
        month_first_day                                  AS measurement_month,
        LAG(cum_balance) OVER (PARTITION BY customer_id
                               ORDER BY month_first_day) AS prev_balance
    FROM cum_bal
),
all_balances AS (   -- replace negatives with 0, nulls (first month for a user) with 0
    SELECT
        measurement_month,
        CASE
            WHEN prev_balance IS NULL OR prev_balance < 0 THEN 0
            ELSE prev_balance
        END AS clean_balance
    FROM prev_month_bal
),
total_by_month AS ( -- total balance across all users for each month
    SELECT
        measurement_month,
        SUM(clean_balance) AS total_balance
    FROM all_balances
    GROUP BY measurement_month
),
final AS (          -- drop the very first month (baseline only)
    SELECT *
    FROM total_by_month
    WHERE measurement_month >
          (SELECT MIN(measurement_month) FROM total_by_month)
)
SELECT
    measurement_month AS month,
    total_balance
FROM final
ORDER BY month;