WITH monthly_net AS (   /* 1.  net amount per customer & month (1st day of month) */
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date",'YYYY-MM-DD'))                  AS "month_start",
        SUM(
            CASE 
                WHEN LOWER("txn_type") = 'deposit'                      THEN  "txn_amount"
                WHEN LOWER("txn_type") IN ('withdrawal','withdraw')     THEN - "txn_amount"
                ELSE 0
            END
        )                                                                   AS "monthly_net"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY 
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date",'YYYY-MM-DD'))
),

closing_balances AS (   /* 2.  running (closing) balance per customer */
    SELECT
        "customer_id",
        "month_start",
        "monthly_net",
        SUM("monthly_net") OVER 
            (PARTITION BY "customer_id" ORDER BY "month_start")             AS "closing_balance"
    FROM monthly_net
),

growth_calc AS (        /* 3.  bring in previous-month closing balance */
    SELECT
        "customer_id",
        "month_start",
        "closing_balance",
        LAG("closing_balance") OVER 
            (PARTITION BY "customer_id" ORDER BY "month_start")             AS "prev_balance"
    FROM closing_balances
),

growth_rates AS (       /* 4.  growth rate for each month */
    SELECT
        "customer_id",
        "month_start",
        "closing_balance",
        COALESCE("prev_balance",0)                                          AS "prev_balance",
        CASE 
            WHEN COALESCE("prev_balance",0) = 0 
                 THEN "closing_balance" * 100
            ELSE ("closing_balance" - "prev_balance") / "prev_balance" * 100
        END                                                                 AS "growth_rate"
    FROM growth_calc
),

latest_month AS (       /* 5.  most-recent month per customer */
    SELECT
        "customer_id",
        "growth_rate"
    FROM growth_rates
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "customer_id" 
                               ORDER BY "month_start" DESC) = 1
)

/* 6.  percentage of customers whose latest-month growth rate > 5 % */
SELECT
    ROUND( 100.0 * SUM(CASE WHEN "growth_rate" > 5 THEN 1 ELSE 0 END) 
           / COUNT(*), 4)                                                   AS "pct_customers_growth_gt_5"
FROM latest_month;