WITH customer_ltv AS (                                  -- 1. each customer's lifetime value & first purchase
    SELECT
        customer_id,
        SUM(amount)                       AS total_ltv,
        MIN(payment_date)                 AS first_payment_date
    FROM payment
    GROUP BY customer_id
),
customer_windows AS (                                  -- 2. sales made within 7‑day & 30‑day windows
    SELECT
        c.customer_id,
        c.total_ltv,
        SUM( CASE                             -- sales in first 7×24h
                 WHEN p.payment_date 
                      <= datetime(c.first_payment_date,'+7 days')
                 THEN p.amount ELSE 0 END )   AS sales_7d,
        SUM( CASE                             -- sales in first 30×24h
                 WHEN p.payment_date 
                      <= datetime(c.first_payment_date,'+30 days')
                 THEN p.amount ELSE 0 END )   AS sales_30d
    FROM customer_ltv  AS c
    JOIN payment       AS p
         ON p.customer_id = c.customer_id
    GROUP BY c.customer_id
),
customer_pct AS (                                    -- 3. percentage of LTV realised in each window
    SELECT
        customer_id,
        total_ltv,
        (sales_7d  * 1.0) / total_ltv AS pct_7d,
        (sales_30d * 1.0) / total_ltv AS pct_30d
    FROM customer_windows
    WHERE total_ltv > 0                             -- exclude customers with zero LTV
)
SELECT                                                -- 4. overall averages
    ROUND( AVG(pct_7d)  * 100 , 4 ) AS avg_pct_7d,    -- % of LTV in first 7 days
    ROUND( AVG(pct_30d) * 100 , 4 ) AS avg_pct_30d,   -- % of LTV in first 30 days
    ROUND( AVG(total_ltv)       , 4 ) AS avg_total_ltv
FROM customer_pct;