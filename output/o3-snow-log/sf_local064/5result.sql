/* ----------------------------------------------------------
   1.  Calculate every customer’s month-end balance for 2020
       (deposits  –  withdrawals  within the month)
   2.  Find the month with the MOST customers whose balance > 0
       and the month with the FEWEST.
   3.  For those two months, return the average month-end balance
       (all customers that transacted in the month) and
       the difference between the two averages.
-----------------------------------------------------------*/
WITH txn_2020 AS (   /* keep only 2020 transactions and cast date */
    SELECT
        "customer_id",
        TO_DATE("txn_date")          AS txn_dt,
        "txn_amount"                 AS amt,
        UPPER("txn_type")            AS txn_type
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    WHERE YEAR(TO_DATE("txn_date")) = 2020
),

monthly_balances AS (   /* net movement within each month          */
    SELECT
        "customer_id",
        TO_CHAR(txn_dt,'YYYY-MM')    AS month_yyyy_mm,
        SUM(
            CASE 
                 WHEN txn_type = 'DEPOSIT'                      THEN  amt
                 WHEN txn_type IN ('WITHDRAWAL','WITHDRAW')     THEN -amt
                 ELSE 0
            END
        ) AS month_end_balance
    FROM txn_2020
    GROUP BY "customer_id", TO_CHAR(txn_dt,'YYYY-MM')
),

month_positive_counts AS (  /* customers with positive balances   */
    SELECT
        month_yyyy_mm,
        COUNT_IF(month_end_balance > 0) AS positive_cust_cnt
    FROM monthly_balances
    GROUP BY month_yyyy_mm
),

max_month AS (             /* month with MOST positive balances   */
    SELECT month_yyyy_mm   AS high_month
    FROM   month_positive_counts
    ORDER  BY positive_cust_cnt DESC NULLS LAST, month_yyyy_mm
    LIMIT  1
),

min_month AS (             /* month with FEWEST positive balances */
    SELECT month_yyyy_mm   AS low_month
    FROM   month_positive_counts
    ORDER  BY positive_cust_cnt ASC NULLS LAST, month_yyyy_mm
    LIMIT  1
),

avg_balances AS (          /* average month-end balance for the 2 months */
    SELECT
        month_yyyy_mm,
        AVG(month_end_balance) AS avg_month_end_balance
    FROM monthly_balances
    WHERE month_yyyy_mm IN (SELECT high_month FROM max_month)
          OR month_yyyy_mm IN (SELECT low_month  FROM min_month)
    GROUP BY month_yyyy_mm
),

results AS (               /* pivot the two averages onto one row */
    SELECT
        (SELECT high_month FROM max_month)                                              AS highest_positive_balance_month,
        (SELECT low_month  FROM min_month)                                              AS lowest_positive_balance_month,
        MAX(CASE WHEN month_yyyy_mm = (SELECT high_month FROM max_month)
                 THEN avg_month_end_balance END)                                        AS average_balance_highest_month,
        MAX(CASE WHEN month_yyyy_mm = (SELECT low_month FROM min_month)
                 THEN avg_month_end_balance END)                                        AS average_balance_lowest_month
    FROM avg_balances
)

SELECT
    highest_positive_balance_month,
    lowest_positive_balance_month,
    average_balance_highest_month,
    average_balance_lowest_month,
    (average_balance_highest_month - average_balance_lowest_month)  AS difference_between_averages
FROM results;