WITH monthly_balances AS (      /* month-end balance for every customer */
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date",'YYYY-MM-DD'))            AS month_start,
        SUM(
            CASE 
                WHEN LOWER("txn_type") = 'deposit'    THEN  "txn_amount"
                WHEN LOWER("txn_type") = 'withdrawal' THEN - "txn_amount"
                ELSE 0
            END
        )                                                               AS month_end_balance
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    WHERE EXTRACT(year FROM TO_DATE("txn_date",'YYYY-MM-DD')) = 2020
    GROUP BY "customer_id", month_start
),
month_stats AS (                 /* per-month statistics */
    SELECT
        month_start,
        /* customers with a positive balance */
        SUM(CASE WHEN month_end_balance > 0 THEN 1 ELSE 0 END)          AS positive_customer_count,
        AVG(month_end_balance)                                          AS avg_month_end_balance
    FROM monthly_balances
    GROUP BY month_start
),
high_month AS (                  /* month with most positive balances */
    SELECT
        month_start          AS high_month,
        positive_customer_count AS high_positive_cnt,
        avg_month_end_balance   AS high_avg_bal
    FROM month_stats
    ORDER BY positive_customer_count DESC NULLS LAST, month_start
    LIMIT 1
),
low_month AS (                   /* month with fewest positive balances */
    SELECT
        month_start          AS low_month,
        positive_customer_count AS low_positive_cnt,
        avg_month_end_balance   AS low_avg_bal
    FROM month_stats
    ORDER BY positive_customer_count ASC NULLS LAST, month_start
    LIMIT 1
)
SELECT
    TO_CHAR(high_month, 'YYYY-MM')                           AS high_month,
    high_positive_cnt                                        AS high_positive_customers,
    ROUND(high_avg_bal,4)                                    AS high_month_avg_balance,
    TO_CHAR(low_month,  'YYYY-MM')                           AS low_month,
    low_positive_cnt                                         AS low_positive_customers,
    ROUND(low_avg_bal,4)                                     AS low_month_avg_balance,
    ROUND(high_avg_bal - low_avg_bal,4)                      AS avg_balance_difference
FROM high_month, low_month;