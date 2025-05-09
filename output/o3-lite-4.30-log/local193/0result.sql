WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(payment_date) AS first_purchase_dt
    FROM payment
    GROUP BY customer_id
),
payments AS (
    SELECT
        p.customer_id,
        p.amount,
        p.payment_date,
        fp.first_purchase_dt,
        (julianday(p.payment_date) - julianday(fp.first_purchase_dt)) * 86400.0 AS seconds_since_first
    FROM payment AS p
    JOIN first_purchase AS fp
      ON p.customer_id = fp.customer_id
),
per_customer AS (
    SELECT
        customer_id,
        SUM(amount) AS lifetime_sales,
        SUM(CASE WHEN seconds_since_first <= 604800  THEN amount ELSE 0 END) AS sales_7d,
        SUM(CASE WHEN seconds_since_first <= 2592000 THEN amount ELSE 0 END) AS sales_30d
    FROM payments
    GROUP BY customer_id
    HAVING SUM(amount) > 0
),
percentages AS (
    SELECT
        customer_id,
        lifetime_sales,
        sales_7d  * 100.0 / lifetime_sales AS pct_7d,
        sales_30d * 100.0 / lifetime_sales AS pct_30d
    FROM per_customer
)
SELECT
    ROUND(AVG(lifetime_sales),4) AS average_total_lifetime_sales,
    ROUND(AVG(pct_7d),4)         AS pct_ltv_first_7_days,
    ROUND(AVG(pct_30d),4)        AS pct_ltv_first_30_days
FROM percentages;