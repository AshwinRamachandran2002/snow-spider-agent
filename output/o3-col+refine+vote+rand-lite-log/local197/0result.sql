WITH top_ten AS (
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    ORDER BY SUM(amount) DESC
    LIMIT 10
),
monthly_totals AS (
    SELECT
        p.customer_id,
        strftime('%Y-%m', p.payment_date) AS pay_month,
        SUM(p.amount)                    AS monthly_total
    FROM payment AS p
    JOIN top_ten  t ON t.customer_id = p.customer_id
    GROUP BY p.customer_id, pay_month
),
mom AS (
    SELECT
        m1.customer_id,
        m0.pay_month                              AS prev_month,
        m1.pay_month                              AS curr_month,
        ROUND(m1.monthly_total - m0.monthly_total, 2) AS mom_diff
    FROM monthly_totals AS m1
    JOIN monthly_totals AS m0
      ON m1.customer_id = m0.customer_id
     AND m1.pay_month  = strftime('%Y-%m',
         date(m0.pay_month || '-01', '+1 month'))
),
winner AS (
    SELECT *
    FROM mom
    ORDER BY ABS(mom_diff) DESC
    LIMIT 1
)
SELECT
    w.customer_id,
    c.first_name || ' ' || c.last_name            AS customer_name,
    w.prev_month || ' → ' || w.curr_month         AS period,
    w.mom_diff                                    AS largest_mom_difference
FROM winner AS w
JOIN customer AS c ON c.customer_id = w.customer_id;