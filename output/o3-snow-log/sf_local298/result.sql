/* -----------------------------------------------------------
   For every calendar month:
   1. Work out each user’s running BTC balance (BUY = +, SELL = -)
      – any negative running balances are reset to zero.
   2. Sum those adjusted balances across all users → “total_balance”.
   3. Attach the previous-month’s total_balance and keep only rows
      where a valid previous balance exists (i.e. drop the very first
      month which serves purely as a baseline).
   ----------------------------------------------------------- */
WITH txn_monthly AS (          -- net quantity per user per month
    SELECT
        "member_id",
        DATE_TRUNC('month', TO_DATE("txn_date", 'DD-MM-YYYY'))    AS "month_start",
        SUM( CASE WHEN "txn_type" = 'BUY'  THEN  "quantity"
                  WHEN "txn_type" = 'SELL' THEN -1 * "quantity"
             END )                                               AS "net_qty"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_TRANSACTIONS"
    GROUP BY "member_id", "month_start"
),
running_bal AS (              -- cumulative balance per user
    SELECT
        "member_id",
        "month_start",
        SUM("net_qty") OVER (PARTITION BY "member_id"
                             ORDER BY "month_start"
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "running_balance"
    FROM txn_monthly
),
adjusted_bal AS (             -- replace negatives with zero
    SELECT
        "member_id",
        "month_start",
        CASE WHEN "running_balance" < 0 THEN 0 ELSE "running_balance" END AS "adj_balance"
    FROM running_bal
),
total_bal_monthly AS (        -- total balance across all users
    SELECT
        "month_start",
        SUM("adj_balance") AS "total_balance"
    FROM adjusted_bal
    GROUP BY "month_start"
)
SELECT
    TO_CHAR("month_start", 'YYYY-MM')                 AS "month_flag",
    LAG("total_balance") OVER (ORDER BY "month_start") AS "total_balance_prev_month"
FROM total_bal_monthly
QUALIFY "total_balance_prev_month" IS NOT NULL        -- drop the first month (no prior month)
ORDER BY "month_start";