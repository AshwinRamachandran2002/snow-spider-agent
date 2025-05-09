WITH tx AS (   /* 1. sign every transaction and map it to first day of month */
    SELECT 
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date",'YYYY-MM-DD'))              AS month_start,
        CASE 
            WHEN LOWER("txn_type") = 'deposit'     THEN  "txn_amount"
            WHEN LOWER("txn_type") = 'withdrawal'  THEN - "txn_amount"
            ELSE 0
        END                                                               AS signed_amt
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
), 

monthly_net AS (   /* 2. net amount per customer per month */
    SELECT
        "customer_id",
        month_start,
        SUM(signed_amt)                                                   AS net_amount
    FROM tx
    GROUP BY "customer_id", month_start
), 

closing_bal AS (   /* 3. month-end (closing) balance = cumulative net */
    SELECT
        "customer_id",
        month_start,
        net_amount,
        SUM(net_amount) OVER (PARTITION BY "customer_id"
                              ORDER BY month_start)                       AS closing_balance
    FROM monthly_net
), 

growth AS (        /* 4. month-on-month growth rate */
    SELECT
        "customer_id",
        month_start,
        closing_balance,
        LAG(closing_balance) OVER (PARTITION BY "customer_id"
                                   ORDER BY month_start)                  AS prev_balance,
        CASE 
            WHEN LAG(closing_balance) OVER (PARTITION BY "customer_id"
                                            ORDER BY month_start) IS NULL
                 THEN NULL                                              /* first month */
            WHEN LAG(closing_balance) OVER (PARTITION BY "customer_id"
                                            ORDER BY month_start) = 0
                 THEN closing_balance * 100
            ELSE (closing_balance
                  - LAG(closing_balance) OVER (PARTITION BY "customer_id"
                                               ORDER BY month_start))
                 / LAG(closing_balance) OVER (PARTITION BY "customer_id"
                                               ORDER BY month_start) * 100
        END                                                             AS growth_rate
    FROM closing_bal
), 

latest_growth AS ( /* 5. keep only most-recent month for each customer */
    SELECT
        "customer_id",
        growth_rate
    FROM growth
    QUALIFY month_start = MAX(month_start) OVER (PARTITION BY "customer_id")
), 

agg AS (           /* 6. aggregate to get percentage of customers >5% growth */
    SELECT
        COUNT(DISTINCT "customer_id")                                  AS total_customers,
        COUNT_IF(growth_rate > 5)                                      AS grow_customers
    FROM latest_growth
)

SELECT
    grow_customers,
    total_customers,
    ROUND(grow_customers * 100.0 / total_customers, 4) AS pct_customers_gt_5_growth
FROM agg;