WITH monthly AS (
    /* 1.  Total payments per customer for each year‑month */
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS ym,
        SUM(amount) AS total_amount
    FROM payment
    GROUP BY customer_id, ym
),
diffs AS (
    /* 2.  Month‑to‑month differences using LAG */
    SELECT
        customer_id,
        ym,
        total_amount,
        LAG(total_amount) OVER (PARTITION BY customer_id ORDER BY ym) AS prev_total
    FROM monthly
),
changes AS (
    /* 3.  Absolute change for months that have a previous month */
    SELECT
        customer_id,
        ABS(total_amount - prev_total) AS change
    FROM diffs
    WHERE prev_total IS NOT NULL
),
avg_change AS (
    /* 4.  Average monthly change for each customer */
    SELECT
        customer_id,
        AVG(change) AS avg_monthly_change
    FROM changes
    GROUP BY customer_id
),
top_customer AS (
    /* 5.  Customer with the highest average monthly change */
    SELECT customer_id
    FROM avg_change
    ORDER BY avg_monthly_change DESC, customer_id
    LIMIT 1
)
/* 6.  Return the full name of that customer */
SELECT
    c.first_name || ' ' || c.last_name AS full_name
FROM customer AS c
JOIN top_customer AS t
  ON c.customer_id = t.customer_id;