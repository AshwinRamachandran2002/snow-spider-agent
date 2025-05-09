/*-----------------------------------------------------------
  Calculate each month’s total user balance as of the 1st day,
  then return the previous-month total (negative values floored
  to zero) for every month after the first one.
-----------------------------------------------------------*/
WITH monthly_net_flow AS (   -- step 1: monthly net deposits / withdrawals per customer
    SELECT
        "customer_id",
        TO_CHAR(DATE_TRUNC('month', TO_DATE("txn_date",'YYYY-MM-DD')), 'YYYY-MM')  AS "year_month",
        SUM(CASE
                WHEN "txn_type" = 'deposit'     THEN  "txn_amount"
                WHEN "txn_type" = 'withdrawal'  THEN - "txn_amount"
                ELSE 0
            END)                                                                   AS "net_flow"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."CUSTOMER_TRANSACTIONS"
    GROUP BY
        "customer_id",
        TO_CHAR(DATE_TRUNC('month', TO_DATE("txn_date",'YYYY-MM-DD')), 'YYYY-MM')
),

cumulative_balances AS (     -- step 2: running balance for every customer by month
    SELECT
        "customer_id",
        "year_month",
        SUM("net_flow") 
            OVER (PARTITION BY "customer_id"
                  ORDER BY "year_month"
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)                AS "cum_balance"
    FROM monthly_net_flow
),

total_monthly_balance AS (   -- step 3: total market balance at the start of each month
    SELECT
        "year_month",
        SUM("cum_balance")                                                          AS "total_balance"
    FROM cumulative_balances
    GROUP BY "year_month"
),

previous_month_totals AS (   -- step 4: bring forward previous month’s total balance
    SELECT
        "year_month",
        LAG("total_balance") OVER (ORDER BY "year_month")                           AS "prev_total_balance"
    FROM total_monthly_balance
)

SELECT
    "year_month",
    IFF("prev_total_balance" < 0, 0, "prev_total_balance")  AS "prev_month_total_balance"
FROM previous_month_totals
WHERE "prev_total_balance" IS NOT NULL          -- exclude the very first month
ORDER BY "year_month";