WITH first_payment AS (          -- initial purchase moment for every customer
    SELECT 
        customer_id,
        MIN(payment_date) AS initial_purchase
    FROM payment
    GROUP BY customer_id
),
customer_sales AS (              -- total lifetime sales (exclude zero‑LTV customers)
    SELECT
        customer_id,
        SUM(amount) AS lifetime_sales
    FROM payment
    GROUP BY customer_id
    HAVING SUM(amount) > 0
),
sales_7 AS (                     -- sales in the first 7×24 hours after first purchase
    SELECT
        p.customer_id,
        SUM(p.amount) AS sales_7
    FROM payment p
    JOIN first_payment fp
        ON fp.customer_id = p.customer_id
    WHERE p.payment_date <= DATETIME(fp.initial_purchase,'+7 days')
    GROUP BY p.customer_id
),
sales_30 AS (                    -- sales in the first 30×24 hours after first purchase
    SELECT
        p.customer_id,
        SUM(p.amount) AS sales_30
    FROM payment p
    JOIN first_payment fp
        ON fp.customer_id = p.customer_id
    WHERE p.payment_date <= DATETIME(fp.initial_purchase,'+30 days')
    GROUP BY p.customer_id
),
customer_metrics AS (            -- per‑customer percentages
    SELECT
        cs.customer_id,
        cs.lifetime_sales,
        COALESCE(s7.sales_7,0)  AS sales_7,
        COALESCE(s30.sales_30,0) AS sales_30,
        (COALESCE(s7.sales_7,0)  * 100.0) / cs.lifetime_sales AS pct_7,
        (COALESCE(s30.sales_30,0) * 100.0) / cs.lifetime_sales AS pct_30
    FROM customer_sales cs
    LEFT JOIN sales_7  s7  ON s7.customer_id  = cs.customer_id
    LEFT JOIN sales_30 s30 ON s30.customer_id = cs.customer_id
)
SELECT
    ROUND(AVG(pct_7), 4)  AS avg_pct_first_7_days,
    ROUND(AVG(pct_30),4)  AS avg_pct_first_30_days,
    ROUND(AVG(lifetime_sales),4) AS avg_total_ltv
FROM customer_metrics;