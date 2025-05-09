WITH top_customers AS (          -- 1. 10 customers who paid the most in total
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    ORDER BY SUM(amount) DESC
    LIMIT 10
),
monthly_totals AS (              -- 2. monthly totals for those customers
    SELECT
        customer_id,
        strftime('%Y', payment_date)  AS yr,
        strftime('%m', payment_date)  AS mn,
        SUM(amount)                   AS month_sum
    FROM payment
    WHERE customer_id IN (SELECT customer_id FROM top_customers)
    GROUP BY customer_id, yr, mn
),
ordered_months AS (              -- 3. give each month a sequence number per customer
    SELECT
        customer_id,
        yr,
        mn,
        month_sum,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY yr, mn) AS rn
    FROM monthly_totals
),
month_diffs AS (                 -- 4. month‑over‑month absolute differences
    SELECT
        cur.customer_id,
        cur.yr,
        cur.mn,
        ABS(cur.month_sum - prev.month_sum) AS diff_amt
    FROM ordered_months cur
    JOIN ordered_months prev
      ON cur.customer_id = prev.customer_id
     AND cur.rn = prev.rn + 1      -- previous month for same customer
)
SELECT
    customer_id,
    (yr || '-' || mn) AS month,    -- month in which the change was observed
    ROUND(diff_amt, 2) AS difference
FROM month_diffs
ORDER BY diff_amt DESC
LIMIT 1;