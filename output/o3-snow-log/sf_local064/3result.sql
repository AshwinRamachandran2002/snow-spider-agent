/*-----------------------------------------------------------
Step-1 : create a 12-row calendar for every month of 2020
-----------------------------------------------------------*/
WITH months AS (
    SELECT DATE_TRUNC('month',
                      DATEADD(month, seq4(), '2020-01-01'::date)
                     )                  AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
),
/*-----------------------------------------------------------
Step-2 : list of every customer who transacted in 2020
-----------------------------------------------------------*/
customers AS (
    SELECT DISTINCT "customer_id"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    WHERE YEAR(TO_DATE("txn_date")) = 2020
),
/*-----------------------------------------------------------
Step-3 : net amount (deposits – withdrawals) per
         customer-month within 2020
-----------------------------------------------------------*/
balances AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date"))            AS month_start,
        SUM( CASE
                 WHEN LOWER("txn_type") = 'deposit'     THEN  "txn_amount"
                 WHEN LOWER("txn_type") = 'withdrawal'  THEN - "txn_amount"
                 ELSE 0
             END )                                         AS net_amount
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    WHERE YEAR(TO_DATE("txn_date")) = 2020
    GROUP BY "customer_id", month_start
),
/*-----------------------------------------------------------
Step-4 : ensure every customer appears in every month,
         use 0 when no activity
-----------------------------------------------------------*/
customer_month_balances AS (
    SELECT
        c."customer_id",
        m.month_start,
        COALESCE(b.net_amount, 0)       AS month_end_balance
    FROM customers              c
    CROSS JOIN months           m
    LEFT  JOIN balances         b
           ON  b."customer_id" = c."customer_id"
           AND b.month_start    = m.month_start
),
/*-----------------------------------------------------------
Step-5 : per-month statistics
-----------------------------------------------------------*/
per_month_stats AS (
    SELECT
        month_start,
        COUNT_IF(month_end_balance > 0)         AS positive_balance_customers,
        AVG(month_end_balance)                  AS avg_balance
    FROM customer_month_balances
    GROUP BY month_start
),
/*-----------------------------------------------------------
Step-6 : month with most / least positive-balance customers
-----------------------------------------------------------*/
highest_month AS (
    SELECT *
    FROM   per_month_stats
    ORDER  BY positive_balance_customers DESC NULLS LAST,
             month_start                                   /* deterministic tie-break */
    LIMIT 1
),
lowest_month AS (
    SELECT *
    FROM   per_month_stats
    ORDER  BY positive_balance_customers ASC NULLS LAST,
             month_start                                   /* deterministic tie-break */
    LIMIT 1
)
/*-----------------------------------------------------------
Step-7 : final answer
-----------------------------------------------------------*/
SELECT
    h.month_start               AS highest_positive_balance_month,
    l.month_start               AS lowest_positive_balance_month,
    h.avg_balance               AS average_balance_highest_month,
    l.avg_balance               AS average_balance_lowest_month,
    h.avg_balance - l.avg_balance
                                 AS average_balance_difference
FROM  highest_month h
CROSS JOIN lowest_month  l;