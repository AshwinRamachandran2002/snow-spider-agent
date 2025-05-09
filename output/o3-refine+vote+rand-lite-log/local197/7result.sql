WITH top_customers AS (                            -- 1. 10 highest‑spending customers overall
    SELECT customer_id,
           SUM(amount) AS total_paid
    FROM payment
    GROUP BY customer_id
    ORDER BY total_paid DESC
    LIMIT 10
),
monthly_totals AS (                                -- 2. monthly total for each of those customers
    SELECT p.customer_id,
           strftime('%Y-%m', p.payment_date) AS month,   -- YYYY‑MM
           SUM(p.amount)             AS month_paid
    FROM payment p
    JOIN top_customers tc ON tc.customer_id = p.customer_id
    GROUP BY p.customer_id, month
),
month_over_month AS (                              -- 3. month‑over‑month absolute change
    SELECT customer_id,
           month,                                  -- later month in the pair
           ABS(month_paid
               - LAG(month_paid) OVER (PARTITION BY customer_id ORDER BY month)
              ) AS diff
    FROM monthly_totals
)
SELECT  c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        m.month,
        ROUND(m.diff, 2)          AS max_monthly_change
FROM    month_over_month m
JOIN    customer c ON c.customer_id = m.customer_id
WHERE   m.diff IS NOT NULL
ORDER BY m.diff DESC                 -- 4. largest change
LIMIT 1;