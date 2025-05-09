WITH top_customers AS (           -- 1. ten biggest spenders overall
    SELECT customer_id,
           SUM(amount) AS total_paid
    FROM payment
    GROUP BY customer_id
    ORDER BY total_paid DESC
    LIMIT 10
),
monthly_totals AS (               -- 2. monthly payment totals for those customers
    SELECT
        p.customer_id,
        strftime('%Y-%m', p.payment_date) AS month,   -- YYYY-MM
        SUM(p.amount) AS month_total
    FROM payment p
    JOIN top_customers tc USING (customer_id)
    GROUP BY p.customer_id, month
),
differences AS (                  -- 3. month‑over‑month differences
    SELECT
        customer_id,
        month,
        month_total,
        LAG(month_total) OVER (PARTITION BY customer_id ORDER BY month) AS prev_month_total
    FROM monthly_totals
),
changes AS (                      -- 4. absolute change, rounded
    SELECT
        customer_id,
        month,
        ROUND(ABS(month_total - prev_month_total), 2) AS diff
    FROM differences
    WHERE prev_month_total IS NOT NULL
)
SELECT
    customer_id,
    month,
    diff                          -- largest month‑over‑month change
FROM changes
ORDER BY diff DESC
LIMIT 1;