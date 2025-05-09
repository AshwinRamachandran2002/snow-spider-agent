WITH top10 AS (                          -- 1) Ten customers who paid the most in total
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    ORDER BY SUM(amount) DESC
    LIMIT 10
),
monthly AS (                             -- 2) Their payment totals by calendar month
    SELECT
        p.customer_id,
        strftime('%Y-%m', p.payment_date) AS yr_mo,
        SUM(p.amount)                     AS monthly_total
    FROM payment AS p
    JOIN top10  USING (customer_id)
    GROUP BY p.customer_id, yr_mo
),
diffs AS (                               -- 3) Month‑over‑month change per customer
    SELECT
        customer_id,
        yr_mo,
        monthly_total
          - LAG(monthly_total) OVER (PARTITION BY customer_id ORDER BY yr_mo) AS diff
    FROM monthly
)
SELECT                                   -- 4) Largest absolute change among them
    customer_id,
    yr_mo  AS month_with_max_change,
    ROUND(diff, 2) AS max_month_over_month_difference
FROM diffs
WHERE diff IS NOT NULL
ORDER BY ABS(diff) DESC
LIMIT 1;