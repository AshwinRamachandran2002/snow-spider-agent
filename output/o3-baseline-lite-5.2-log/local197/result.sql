WITH top_customers AS (              -- 1. 10 customers who paid the most in total
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    ORDER BY SUM(amount) DESC
    LIMIT 10
),
monthly_totals AS (                  -- 2. monthly payment totals for those customers
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS month,   -- YYYY‑MM
        SUM(amount) AS month_total
    FROM payment
    WHERE customer_id IN (SELECT customer_id FROM top_customers)
    GROUP BY customer_id, month
),
month_diffs AS (                     -- 3. month‑over‑month absolute differences
    SELECT
        customer_id,
        month,
        ROUND(ABS(month_total 
              - LAG(month_total) OVER (PARTITION BY customer_id ORDER BY month)), 2) AS diff
    FROM monthly_totals
)
SELECT
    customer_id,
    month,         -- this is the month in which the biggest jump/drop is observed
    diff           -- largest month‑over‑month change, rounded to 2 decimals
FROM month_diffs
WHERE diff IS NOT NULL
ORDER BY diff DESC
LIMIT 1;