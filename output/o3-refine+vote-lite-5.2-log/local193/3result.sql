WITH customer_first_and_ltv AS (
    /* 1.  First purchase moment and total lifetime value (LTV) for every customer    */
    SELECT
        customer_id,
        MIN(payment_date)                         AS first_purchase_ts,
        SUM(amount)                               AS lifetime_sales
    FROM payment
    GROUP BY customer_id
),
customer_windows AS (
    /* 2.  Sales that land inside the 7‑day and 30‑day windows that start
           at the exact first_purchase_ts (to the second)                 */
    SELECT
        c.customer_id,
        c.lifetime_sales,
        SUM(CASE
                WHEN p.payment_date <= DATETIME(c.first_purchase_ts,'+7 days')
                THEN p.amount ELSE 0 END)        AS sales_7d,
        SUM(CASE
                WHEN p.payment_date <= DATETIME(c.first_purchase_ts,'+30 days')
                THEN p.amount ELSE 0 END)        AS sales_30d
    FROM customer_first_and_ltv AS c
    JOIN payment                     AS p
          ON p.customer_id = c.customer_id
    GROUP BY c.customer_id, c.lifetime_sales
),
customer_percentages AS (
    /* 3.  Convert the 7‑ and 30‑day amounts to percentages of lifetime sales,
           excluding customers whose lifetime sales are zero                */
    SELECT
        customer_id,
        lifetime_sales,
        (sales_7d  * 100.0) / lifetime_sales     AS pct_7d,
        (sales_30d * 100.0) / lifetime_sales     AS pct_30d
    FROM customer_windows
    WHERE lifetime_sales > 0
)
/* 4.  Aggregate across all eligible customers to get the requested averages */
SELECT
    ROUND(AVG(pct_7d),   4)  AS avg_pct_of_ltv_first_7_days,
    ROUND(AVG(pct_30d),  4)  AS avg_pct_of_ltv_first_30_days,
    ROUND(AVG(lifetime_sales),4) AS avg_total_lifetime_sales
FROM customer_percentages;