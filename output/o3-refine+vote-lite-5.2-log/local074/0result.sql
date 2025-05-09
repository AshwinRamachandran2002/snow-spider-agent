WITH RECURSIVE
/* 1. For every customer work out the first and last month they appear in the data */
customer_range AS (
    SELECT
        customer_id,
        date(min(txn_date), 'start of month') AS start_month,
        date(max(txn_date), 'start of month') AS end_month
    FROM customer_transactions
    GROUP BY customer_id
),

/* 2. Generate every month between the first and last month (inclusive) for each customer */
months (customer_id, month_start) AS (
    SELECT customer_id, start_month
    FROM customer_range
    UNION ALL
    SELECT customer_id, date(month_start, '+1 month')
    FROM months
    JOIN customer_range USING (customer_id)
    WHERE month_start < end_month
),

/* 3. Work out the net change for each customer‑month
      (deposits are +, anything else is treated as –) */
monthly_change AS (
    SELECT
        customer_id,
        date(txn_date, 'start of month') AS month_start,
        SUM(CASE
                WHEN lower(txn_type) IN ('deposit','credit','transfer_in','+') THEN  txn_amount
                ELSE -txn_amount
            END) AS change_amount
    FROM customer_transactions
    GROUP BY customer_id, month_start
),

/* 4. Combine the generated calendar with the actual changes,
      filling missing months with a zero change */
all_months AS (
    SELECT
        m.customer_id,
        m.month_start,
        COALESCE(mc.change_amount, 0) AS monthly_change
    FROM months  AS m
    LEFT JOIN monthly_change AS mc
           ON mc.customer_id = m.customer_id
          AND mc.month_start  = m.month_start
)

/* 5. Return the monthly changes and running (closing) balances       */
SELECT
    customer_id,
    strftime('%Y-%m', month_start)        AS month_year,
    monthly_change,
    SUM(monthly_change) OVER (
        PARTITION BY customer_id
        ORDER BY month_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS closing_balance
FROM all_months
ORDER BY customer_id, month_start;