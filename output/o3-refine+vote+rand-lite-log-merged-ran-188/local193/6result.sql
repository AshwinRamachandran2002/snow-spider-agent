WITH customer_totals AS (
    SELECT
        customer_id,
        MIN(payment_date)                            AS first_purchase_ts,
        SUM(amount)                                  AS lifetime_sales
    FROM payment
    GROUP BY customer_id
    HAVING SUM(amount) > 0                            -- exclude zero‑LTV customers
),
customer_windows AS (
    SELECT
        p.customer_id,
        ct.lifetime_sales,
        SUM(CASE
                /* within first 7×24h of initial purchase */
                WHEN (julianday(p.payment_date) - julianday(ct.first_purchase_ts)) <= 7
                THEN p.amount ELSE 0 END)            AS sales_7d,
        SUM(CASE
                /* within first 30×24h of initial purchase */
                WHEN (julianday(p.payment_date) - julianday(ct.first_purchase_ts)) <= 30
                THEN p.amount ELSE 0 END)            AS sales_30d
    FROM payment AS p
    JOIN customer_totals AS ct
          ON ct.customer_id = p.customer_id
    GROUP BY p.customer_id
)
SELECT
    AVG( (sales_7d  * 100.0) / lifetime_sales )  AS avg_pct_ltv_first_7_days,
    AVG( (sales_30d * 100.0) / lifetime_sales )  AS avg_pct_ltv_first_30_days,
    AVG( lifetime_sales )                        AS avg_total_lifetime_sales
FROM customer_windows;