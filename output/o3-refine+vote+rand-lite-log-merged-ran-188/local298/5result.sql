WITH monthly_net AS (               -- 1. net movement per customer-month
  SELECT
    "customer_id",
    substr("txn_date",1,7)                       AS "month",
    SUM(CASE WHEN "txn_type"='deposit'
             THEN  "txn_amount"
             ELSE - "txn_amount" END)            AS "net_txn"
  FROM "customer_transactions"
  GROUP BY "customer_id","month"
),
running_bal AS (                   -- 2. running balance at end of each month
  SELECT
    "customer_id",
    "month",
    SUM("net_txn") OVER (PARTITION BY "customer_id"
                         ORDER BY "month")        AS "balance"
  FROM monthly_net
),
shifted AS (                       -- 3. shift balance forward one month
  SELECT
    LEAD("month") OVER (PARTITION BY "customer_id"
                        ORDER BY "month")         AS "month",
    CASE WHEN "balance" < 0
         THEN 0
         ELSE "balance" END                      AS "prev_month_balance"
  FROM running_bal
)
-- 4. sum the (non-negative) previous-month balances across all customers
SELECT
  "month",
  SUM("prev_month_balance") AS "total_balance_prev_month"
FROM shifted
WHERE "month" IS NOT NULL          -- drops the very first calendar month
GROUP BY "month"
ORDER BY "month";