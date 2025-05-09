WITH per_customer AS (
    -- first purchase date and total lifetime value (LTV) per customer
    SELECT
        customer_id,
        MIN(payment_date)                      AS first_payment,
        SUM(amount)                            AS ltv
    FROM payment
    GROUP BY customer_id
),
payments_flagged AS (
    -- label each payment if it falls within 7‑day / 30‑day windows
    SELECT
        p.customer_id,
        p.amount,
        pc.ltv,
        CASE WHEN p.payment_date 
                 <= datetime(pc.first_payment, '+7 days')
             THEN p.amount ELSE 0 END          AS amt_7d,
        CASE WHEN p.payment_date 
                 <= datetime(pc.first_payment, '+30 days')
             THEN p.amount ELSE 0 END          AS amt_30d
    FROM payment p
    JOIN per_customer pc
      ON p.customer_id = pc.customer_id
),
per_customer_sums AS (
    -- aggregate flagged amounts per customer (keep only customers with LTV>0)
    SELECT
        customer_id,
        ltv,
        SUM(amt_7d)   AS ltv_7d,
        SUM(amt_30d)  AS ltv_30d
    FROM payments_flagged
    GROUP BY customer_id
    HAVING ltv > 0
)
SELECT
    AVG(ltv_7d * 1.0 / ltv)  AS avg_pct_first_7_days,
    AVG(ltv_30d * 1.0 / ltv) AS avg_pct_first_30_days,
    AVG(ltv)                 AS avg_total_ltv
FROM per_customer_sums;