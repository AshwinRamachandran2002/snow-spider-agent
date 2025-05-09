WITH top10 AS (   -- 1) ten customers who have paid the most overall
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    ORDER BY SUM(amount) DESC
    LIMIT 10
),
monthly_totals AS (   -- 2) monthly totals for those customers
    SELECT
        p.customer_id,
        strftime('%Y-%m', p.payment_date) AS month,
        SUM(p.amount) AS month_sum
    FROM payment p
    JOIN top10 t
      ON t.customer_id = p.customer_id
    GROUP BY p.customer_id, month
),
mo_changes AS (   -- 3) month‑over‑month changes
    SELECT
        m.customer_id,
        m.month,                    -- current (later) month
        m.month_sum,
        LAG(m.month_sum) OVER (
            PARTITION BY m.customer_id
            ORDER BY m.month
        ) AS prev_month_sum
    FROM monthly_totals m
)
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    mc.month,                                   -- month in which the change is seen
    ROUND(ABS(mc.month_sum - mc.prev_month_sum), 2) AS amount_change
FROM mo_changes mc
JOIN customer c
  ON c.customer_id = mc.customer_id
WHERE mc.prev_month_sum IS NOT NULL            -- need a preceding month
ORDER BY amount_change DESC
LIMIT 1;