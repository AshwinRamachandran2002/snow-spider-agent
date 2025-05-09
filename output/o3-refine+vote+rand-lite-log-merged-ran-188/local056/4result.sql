WITH monthly_totals AS (      -- total amount each customer paid per calendar month
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS ym,
        SUM(amount)                     AS monthly_amount
    FROM payment
    GROUP BY customer_id, ym
),
monthly_changes AS (          -- month‑to‑month absolute change for every customer
    SELECT
        customer_id,
        ABS(monthly_amount 
            - LAG(monthly_amount) OVER (PARTITION BY customer_id ORDER BY ym)
        ) AS abs_change
    FROM monthly_totals
),
avg_changes AS (              -- average of those absolute changes per customer
    SELECT
        customer_id,
        AVG(abs_change) AS avg_monthly_change
    FROM monthly_changes
    WHERE abs_change IS NOT NULL          -- exclude first month (no previous month)
    GROUP BY customer_id
),
max_customer AS (             -- customer with the highest average monthly change
    SELECT customer_id
    FROM   avg_changes
    ORDER BY avg_monthly_change DESC, customer_id
    LIMIT 1
)
SELECT c.first_name || ' ' || c.last_name AS full_name
FROM   customer c
JOIN   max_customer mc USING (customer_id);