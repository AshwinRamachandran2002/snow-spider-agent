WITH daily AS (                                       -- net amount (+ deposit, – otherwise) per customer‑day
    SELECT
        "customer_id",
        "txn_date",
        SUM(
            CASE WHEN "txn_type" = 'deposit'
                 THEN  1.0
                 ELSE -1.0
            END * "txn_amount"
        ) AS net_amount
    FROM "customer_transactions"
    GROUP BY "customer_id", "txn_date"
),
balance AS (                                          -- running balance
    SELECT
        "customer_id",
        "txn_date",
        SUM(net_amount) OVER (
            PARTITION BY "customer_id"
            ORDER BY "txn_date"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_balance
    FROM daily
),
rolling AS (                                          -- 30‑day rolling average, negatives floored to 0
    SELECT
        "customer_id",
        "txn_date",
        CASE
            WHEN AVG(running_balance) OVER (
                     PARTITION BY "customer_id"
                     ORDER BY "txn_date"
                     ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                 ) < 0
            THEN 0
            ELSE AVG(running_balance) OVER (
                     PARTITION BY "customer_id"
                     ORDER BY "txn_date"
                     ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                 )
        END AS rolling_30d_avg
    FROM balance
),
monthly_max AS (                                      -- max rolling average per customer‑month
    SELECT
        "customer_id",
        strftime('%Y-%m', "txn_date") AS month_key,
        MAX(rolling_30d_avg) AS max_30d_avg_in_month
    FROM rolling
    GROUP BY "customer_id", month_key
    HAVING max_30d_avg_in_month IS NOT NULL
),
first_month AS (                                      -- first (baseline) month for every customer
    SELECT
        "customer_id",
        MIN(strftime('%Y-%m', "txn_date")) AS first_month_key
    FROM "customer_transactions"
    GROUP BY "customer_id"
)
SELECT                                                -- monthly total of maxima, excluding baseline month
    mm.month_key AS month,
    ROUND(SUM(mm.max_30d_avg_in_month), 4) AS total_max_30day_avg_balance
FROM monthly_max AS mm
JOIN first_month AS fm USING ("customer_id")
WHERE mm.month_key <> fm.first_month_key
GROUP BY mm.month_key
ORDER BY mm.month_key;