WITH top10 AS (                                  -- 1. ten biggest lifetime payers
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    ORDER BY SUM(amount) DESC
    LIMIT 10
),
monthly AS (                                     -- 2. their month-level payment totals
    SELECT p.customer_id,
           strftime('%Y-%m', p.payment_date) AS yyyy_mm,
           SUM(p.amount)                     AS month_total
    FROM   payment p
    WHERE  p.customer_id IN (SELECT customer_id FROM top10)
    GROUP BY p.customer_id, yyyy_mm
),
diffs AS (                                       -- 3. month-over-month differences
    SELECT customer_id,
           yyyy_mm  AS month_of_change,
           month_total,
           LAG(month_total) OVER (PARTITION BY customer_id ORDER BY yyyy_mm) AS prev_month_total
    FROM   monthly
)
SELECT customer_id,
       month_of_change,
       ROUND(ABS(month_total - prev_month_total), 2) AS abs_difference
FROM   diffs
WHERE  prev_month_total IS NOT NULL              -- exclude each customer’s first month
ORDER BY abs_difference DESC                     -- 4. largest change on top
LIMIT 1;