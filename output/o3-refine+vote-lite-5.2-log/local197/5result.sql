WITH top_customers AS (
    /* 1. Ten customers who have paid the most in total */
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    ORDER BY SUM(amount) DESC
    LIMIT 10
),
monthly_totals AS (
    /* 2. Monthly payment totals for those customers         */
    /*    Month is kept as YYYY‑MM so lexical order = date order */
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS month_ym,
        SUM(amount)                     AS month_total
    FROM payment
    WHERE customer_id IN (SELECT customer_id FROM top_customers)
    GROUP BY customer_id, month_ym
),
month_diffs AS (
    /* 3. Month‑over‑month absolute differences (rounded) */
    SELECT
        customer_id,
        month_ym,                                              -- the later month
        ROUND(ABS(month_total 
              - LAG(month_total) OVER (PARTITION BY customer_id
                                        ORDER BY month_ym)
             ), 2) AS diff_amt
    FROM monthly_totals
)
SELECT
    customer_id,
    month_ym  AS month_with_max_change,
    diff_amt  AS max_month_over_month_difference
FROM month_diffs
WHERE diff_amt IS NOT NULL
ORDER BY diff_amt DESC
LIMIT 1;