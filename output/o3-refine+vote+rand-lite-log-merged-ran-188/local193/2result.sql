WITH first_payment AS (
    -- first purchase moment of every customer
    SELECT
        customer_id,
        MIN(payment_date) AS first_payment_date
    FROM payment
    GROUP BY customer_id
),
customer_sales AS (
    -- sales within 7‑day / 30‑day windows (exact seconds) and lifetime sales
    SELECT
        p.customer_id,
        SUM(p.amount)                                           AS total_sales,
        SUM(
            CASE 
                WHEN (julianday(p.payment_date) - julianday(fp.first_payment_date))*86400 <= 604800
                THEN p.amount ELSE 0 END
        )                                                       AS sales_7_days,
        SUM(
            CASE 
                WHEN (julianday(p.payment_date) - julianday(fp.first_payment_date))*86400 <= 2592000
                THEN p.amount ELSE 0 END
        )                                                       AS sales_30_days
    FROM payment AS p
    JOIN first_payment AS fp
      ON p.customer_id = fp.customer_id
    GROUP BY p.customer_id
),
customer_pct AS (
    -- percentage of lifetime sales in the first 7 and 30 days
    SELECT
        customer_id,
        total_sales,
        sales_7_days  * 1.0 / total_sales    AS pct_7_days,
        sales_30_days * 1.0 / total_sales    AS pct_30_days
    FROM customer_sales
    WHERE total_sales > 0            -- exclude customers with zero LTV
)
SELECT
    ROUND(AVG(pct_7_days), 4)   AS avg_pct_first_7_days,
    ROUND(AVG(pct_30_days), 4)  AS avg_pct_first_30_days,
    ROUND(AVG(total_sales), 4)  AS avg_total_lifetime_sales
FROM customer_pct;