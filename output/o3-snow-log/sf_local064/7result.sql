/* 1. Get 2020 transactions and attach a sign to each amount           */
/* 2. Aggregate to customer-month level to obtain the month-end balance */
/* 3. For every month, count customers with a positive balance and      */
/*    calculate the average balance (all customers)                    */
/* 4. Identify the months with the highest and lowest positive-balance  */
/*    customer counts, take their averages, and compute the difference */

WITH txn_2020 AS (      -- step-1
    SELECT
        "customer_id",
        TO_DATE("txn_date")                           AS txn_date,
        CASE
            WHEN LOWER("txn_type") = 'deposit'     THEN  "txn_amount"
            WHEN LOWER("txn_type") = 'withdrawal'  THEN -1 * "txn_amount"
            ELSE 0
        END                                            AS signed_amount
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    WHERE YEAR(TO_DATE("txn_date")) = 2020
),
customer_month_balance AS (   -- step-2
    SELECT
        "customer_id",
        TO_CHAR(TRUNC(txn_date, 'month'), 'YYYY-MM')   AS month_id,   -- e.g. 2020-01
        SUM(signed_amount)                             AS month_end_balance
    FROM txn_2020
    GROUP BY
        "customer_id",
        month_id
),
month_stats AS (             -- step-3
    SELECT
        month_id,
        COUNT_IF(month_end_balance > 0)                AS positive_customer_count,
        AVG(month_end_balance)                         AS average_balance
    FROM customer_month_balance
    GROUP BY month_id
),
ranked AS (                  -- step-4 (rank months)
    SELECT
        month_id,
        positive_customer_count,
        average_balance,
        RANK() OVER (ORDER BY positive_customer_count DESC) AS rank_high,
        RANK() OVER (ORDER BY positive_customer_count ASC)  AS rank_low
    FROM month_stats
)
SELECT
    MAX(CASE WHEN rank_high = 1 THEN month_id END)         AS highest_positive_month,
    MAX(CASE WHEN rank_high = 1 THEN average_balance END)  AS avg_balance_high_month,
    MAX(CASE WHEN rank_low  = 1 THEN month_id END)         AS lowest_positive_month,
    MAX(CASE WHEN rank_low  = 1 THEN average_balance END)  AS avg_balance_low_month,
    MAX(CASE WHEN rank_high = 1 THEN average_balance END)
      - MAX(CASE WHEN rank_low  = 1 THEN average_balance END)
                                                         AS average_difference
FROM ranked;