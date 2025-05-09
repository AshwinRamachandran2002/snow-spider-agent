/* ---------------------------------------------------------------
   For every calendar month, return the TOTAL balance from *all*
   users as of the FIRST day of the PREVIOUS month.
   • Any negative balance is converted to 0
   • The very first month is kept only as baseline and is excluded
     from the final results
   • Results are sorted chronologically
-----------------------------------------------------------------*/
WITH monthly_net AS (              -- 1. net deposits-withdrawals per customer & month
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date"))                AS "month_start",
        SUM(
            CASE
                WHEN LOWER("txn_type") LIKE '%deposit%'   THEN  "txn_amount"
                WHEN LOWER("txn_type") LIKE '%withdraw%'  THEN -1 * "txn_amount"
                ELSE 0
            END
        )                                                      AS "net_amount"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date"))
),
running_balance AS (             -- 2. running balance per customer (measured 1st of month)
    SELECT
        "customer_id",
        "month_start",
        SUM("net_amount") OVER (
            PARTITION BY "customer_id"
            ORDER BY      "month_start"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                       AS "running_balance"
    FROM monthly_net
),
total_balances AS (              -- 3. total balance across ALL customers each month
    SELECT
        "month_start",
        SUM("running_balance")                                  AS "total_balance_all_users"
    FROM running_balance
    GROUP BY "month_start"
),
prev_month_balances AS (         -- 4. previous-month balance, negative => 0
    SELECT
        "month_start",
        COALESCE(
            IFF(
                LAG("total_balance_all_users") OVER (ORDER BY "month_start") < 0,
                0,
                LAG("total_balance_all_users") OVER (ORDER BY "month_start")
            ),
            0
        )                                                          AS "prev_month_total_balance",
        ROW_NUMBER() OVER (ORDER BY "month_start")                 AS "rn"
    FROM total_balances
)
-- 5. Final output (skip baseline month)
SELECT
    TO_CHAR("month_start", 'YYYY-MM')    AS "year_month",
    "prev_month_total_balance"
FROM prev_month_balances
WHERE "rn" > 1
ORDER BY "month_start" ASC;