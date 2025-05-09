WITH txn_2020 AS (   /* keep only 2020 transactions and convert the date text to DATE */
    SELECT
        "customer_id",
        TO_DATE("txn_date")                          AS txn_date,
        "txn_amount",
        LOWER("txn_type")                            AS txn_type
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    WHERE YEAR(TO_DATE("txn_date")) = 2020
),

month_balance AS (   /* net month-end balance per customer per month */
    SELECT
        "customer_id",
        DATE_TRUNC('month', txn_date)                AS month_start,
        SUM( CASE 
                 WHEN txn_type = 'deposit'    THEN  "txn_amount"
                 WHEN txn_type = 'withdrawal' THEN - "txn_amount"
                 ELSE 0
            END )                                   AS month_end_balance
    FROM txn_2020
    GROUP BY "customer_id",
             DATE_TRUNC('month', txn_date)
),

month_positive_counts AS (  /* how many customers are positive in each month */
    SELECT
        month_start,
        COUNT_IF(month_end_balance > 0)              AS positive_customer_count
    FROM month_balance
    GROUP BY month_start
),

max_month AS (       /* month with the MOST positive customers */
    SELECT month_start AS high_month
    FROM month_positive_counts
    QUALIFY positive_customer_count = MAX(positive_customer_count) OVER ()
    LIMIT 1
),

min_month AS (       /* month with the LEAST positive customers */
    SELECT month_start AS low_month
    FROM month_positive_counts
    QUALIFY positive_customer_count = MIN(positive_customer_count) OVER ()
    LIMIT 1
),

avg_balances AS (    /* average month-end balance for the two selected months */
    SELECT
        m.month_start,
        AVG(b.month_end_balance)                     AS avg_month_end_balance
    FROM ( SELECT high_month AS month_start FROM max_month
           UNION ALL
           SELECT low_month  AS month_start FROM min_month ) m
    JOIN month_balance b
      ON b.month_start = m.month_start
    GROUP BY m.month_start
),

pivoted AS (         /* gather results into single row */
    SELECT
        MAX(CASE WHEN month_start = (SELECT high_month FROM max_month)
                 THEN month_start END)              AS month_with_highest_positive,
        MAX(CASE WHEN month_start = (SELECT low_month FROM min_month)
                 THEN month_start END)              AS month_with_lowest_positive,
        MAX(CASE WHEN month_start = (SELECT high_month FROM max_month)
                 THEN avg_month_end_balance END)    AS avg_balance_highest,
        MAX(CASE WHEN month_start = (SELECT low_month FROM min_month)
                 THEN avg_month_end_balance END)    AS avg_balance_lowest
    FROM avg_balances
)

/* final answer */
SELECT
    month_with_highest_positive,
    avg_balance_highest,
    month_with_lowest_positive,
    avg_balance_lowest,
    (avg_balance_highest - avg_balance_lowest)      AS difference_between_averages
FROM pivoted;