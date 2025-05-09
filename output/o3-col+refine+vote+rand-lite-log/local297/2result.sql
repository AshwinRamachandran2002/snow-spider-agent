WITH monthly AS (
    /* 1.  Net amount per customer & month
          (+) deposits | (–) withdrawals                       */
    SELECT  "customer_id",
            substr("txn_date",1,7) || '-01'          AS "month_start",
            SUM(CASE
                     WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                     WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                END)                                AS net_amount
    FROM    "customer_transactions"
    WHERE   "txn_type" IN ('deposit','withdrawal')
    GROUP BY "customer_id", "month_start"
),
balances AS (
    /* 2.  Running closing balance per customer                 */
    SELECT  "customer_id",
            "month_start",
            SUM(net_amount) OVER (PARTITION BY "customer_id"
                                  ORDER BY "month_start")        AS closing_balance,
            ROW_NUMBER()  OVER (PARTITION BY "customer_id"
                                 ORDER BY "month_start" DESC)    AS rn
    FROM    monthly
),
latest AS (
    /* 3.  Latest and previous-month balances for each customer */
    SELECT  l."customer_id",
            l.closing_balance                       AS latest_bal,
            COALESCE(p.closing_balance,0)           AS prev_bal
    FROM    balances l
    LEFT JOIN balances p
           ON p."customer_id" = l."customer_id"
          AND p.rn           = 2        -- previous month
    WHERE   l.rn = 1                     -- latest month
),
flagged AS (
    /* 4.  Growth rate for the most-recent month                */
    SELECT  "customer_id",
            CASE
                 WHEN prev_bal = 0
                      THEN  latest_bal * 100.0
                 ELSE  (latest_bal - prev_bal) * 100.0 / ABS(prev_bal)
            END  AS growth_rate_pct
    FROM    latest
)
-- 5.  Percentage of customers with growth rate > 5 %
SELECT  ROUND(
            100.0 * SUM(CASE WHEN growth_rate_pct > 5 THEN 1 ELSE 0 END)
                  / COUNT(*),
            4)   AS pct_customers_growth_gt_5
FROM    flagged;