WITH txn_net AS (           /* 1. net amount for every customer on every day */
    SELECT
        customer_id,
        DATE(txn_date)                              AS txn_date,
        SUM(
            CASE 
                WHEN LOWER(txn_type) = 'deposit'    THEN  txn_amount   -- deposits add
                ELSE                                -txn_amount        -- everything else subtracts
            END
        )                                           AS net_amount
    FROM customer_transactions
    GROUP BY customer_id, DATE(txn_date)
),

daily_balance AS (          /* 2. running (cumulative) balance per customer */
    SELECT
        customer_id,
        txn_date,
        SUM(net_amount) 
          OVER (PARTITION BY customer_id
                ORDER BY txn_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)      AS balance
    FROM txn_net
),

balance_30d AS (            /* 3. 30‑day rolling average balance */
    SELECT
        customer_id,
        txn_date,
        AVG(balance) 
          OVER (PARTITION BY customer_id
                ORDER BY txn_date
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)             AS avg_30d_balance
    FROM daily_balance
),

balance_30d_clean AS (      /* 4. keep only rows with full 30‑day window & floor negatives at 0 */
    SELECT
        customer_id,
        txn_date,
        CASE WHEN avg_30d_balance < 0 THEN 0 ELSE avg_30d_balance END  AS adj_avg_balance
    FROM balance_30d
    WHERE avg_30d_balance IS NOT NULL          -- requires at least 30 days of data
),

cust_month_max AS (         /* 5. customer’s maximum 30‑day avg balance per calendar month */
    SELECT
        customer_id,
        STRFTIME('%Y-%m', txn_date)                                AS month_ym,
        MAX(adj_avg_balance)                                       AS max_avg_balance
    FROM balance_30d_clean
    GROUP BY customer_id, STRFTIME('%Y-%m', txn_date)
),

first_month AS (            /* 6. first (baseline) month for every customer */
    SELECT
        customer_id,
        STRFTIME('%Y-%m', MIN(DATE(txn_date)))                     AS first_month_ym
    FROM customer_transactions
    GROUP BY customer_id
),

filtered_max AS (           /* 7. remove each customer’s baseline month */
    SELECT  cm.*
    FROM    cust_month_max  cm
    LEFT    JOIN first_month fm
           ON cm.customer_id = fm.customer_id
          AND cm.month_ym    = fm.first_month_ym
    WHERE   fm.customer_id IS NULL
)

/* 8. final monthly sum of the (non‑baseline) customer maxima */
SELECT
    month_ym                                            AS month,
    ROUND(SUM(max_avg_balance), 4)                      AS total_max_30d_avg_balance
FROM filtered_max
GROUP BY month_ym
ORDER BY month_ym;