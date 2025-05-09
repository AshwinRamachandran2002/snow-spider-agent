WITH top_customers AS (                         -- 1) 10 biggest spenders overall
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    ORDER BY SUM(amount) DESC
    LIMIT 10
),
monthly_totals AS (                             -- 2) their payment total per month
    SELECT
        p.customer_id,
        strftime('%Y-%m', p.payment_date) AS yyyymm,
        SUM(p.amount)                      AS month_total
    FROM payment p
    WHERE p.customer_id IN (SELECT customer_id FROM top_customers)
    GROUP BY p.customer_id, yyyymm
),
mom AS (                                        -- 3) month-over-month change
    SELECT
        customer_id,
        yyyymm,
        month_total,
        LAG(month_total) OVER (PARTITION BY customer_id ORDER BY yyyymm) AS prev_month_total
    FROM monthly_totals
),
mom_diff AS (                                   -- 4) absolute differences
    SELECT
        customer_id,
        yyyymm,
        ROUND(ABS(month_total - prev_month_total), 2) AS diff
    FROM mom
    WHERE prev_month_total IS NOT NULL
),
max_change AS (                                 -- 5) pick the single largest change
    SELECT *
    FROM mom_diff
    ORDER BY diff DESC
    LIMIT 1
)
SELECT
    mc.customer_id,
    c.first_name,
    c.last_name,
    mc.yyyymm  AS month_with_max_change,
    mc.diff    AS largest_mom_difference
FROM max_change mc
JOIN customer c ON c.customer_id = mc.customer_id;