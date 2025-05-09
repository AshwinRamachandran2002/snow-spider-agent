WITH txn_2020 AS (   /* 1.  Month-end balance for every customer in 2020 */
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date"))           AS month_start,
        SUM(
            CASE 
                WHEN LOWER("txn_type") = 'deposit'     THEN  "txn_amount"
                WHEN LOWER("txn_type") = 'withdrawal'  THEN - "txn_amount"
                ELSE 0
            END
        )                                                 AS month_end_balance
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    WHERE YEAR(TO_DATE("txn_date")) = 2020
    GROUP BY "customer_id", month_start
),

metrics AS (         /* 2.  Positive-balance count and average balance for each month */
    SELECT
        month_start,
        COUNT_IF(month_end_balance > 0)                     AS positive_customer_count,
        AVG(month_end_balance)                              AS avg_balance
    FROM txn_2020
    GROUP BY month_start
),

ranked AS (          /* 3.  Rank months by positive-balance count (high & low) */
    SELECT
        month_start,
        positive_customer_count,
        avg_balance,
        RANK() OVER (ORDER BY positive_customer_count DESC) AS r_high,
        RANK() OVER (ORDER BY positive_customer_count ASC)  AS r_low
    FROM metrics
),

highest AS (         /* 4.  Month with the highest number of positive balances */
    SELECT
        month_start           AS month_highest,
        positive_customer_count AS highest_positive_count,
        avg_balance           AS avg_balance_highest
    FROM ranked
    WHERE r_high = 1
    LIMIT 1
),

lowest AS (          /* 5.  Month with the lowest number of positive balances */
    SELECT
        month_start           AS month_lowest,
        positive_customer_count AS lowest_positive_count,
        avg_balance           AS avg_balance_lowest
    FROM ranked
    WHERE r_low = 1
    LIMIT 1
)

/* 6.  Final answer: the two months, their averages, and their difference */
SELECT
    TO_CHAR(h.month_highest, 'YYYY-MM')           AS month_with_most_positive_balances,
    TO_CHAR(l.month_lowest , 'YYYY-MM')           AS month_with_least_positive_balances,
    ROUND(h.avg_balance_highest , 4)              AS avg_balance_highest_month,
    ROUND(l.avg_balance_lowest  , 4)              AS avg_balance_lowest_month,
    ROUND(h.avg_balance_highest - l.avg_balance_lowest , 4)
                                                  AS difference_between_averages
FROM highest h
CROSS JOIN lowest l;