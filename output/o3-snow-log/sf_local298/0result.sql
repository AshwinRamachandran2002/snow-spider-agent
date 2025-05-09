WITH txns AS (   /* add sign to each quantity */
    SELECT
        "member_id",
        TO_DATE("txn_date",'DD-MM-YYYY')                                           AS txn_dt,
        CASE WHEN "txn_type" = 'BUY'  THEN  "quantity"
             WHEN "txn_type" = 'SELL' THEN -1 * "quantity"
             ELSE 0 END                                                           AS effective_qty
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_TRANSACTIONS
),

monthly_net AS (   /* net quantity per user per calendar month */
    SELECT
        "member_id",
        DATE_TRUNC('MONTH', txn_dt)                                                AS month_start,
        SUM(effective_qty)                                                         AS net_qty_month
    FROM txns
    GROUP BY "member_id", month_start
),

cum_balance AS (   /* running balance for every user at the END of each month */
    SELECT
        "member_id",
        month_start,
        SUM(net_qty_month) OVER (PARTITION BY "member_id"
                                 ORDER BY month_start
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_balance
    FROM monthly_net
),

total_balances AS (   /* total balance across ALL users at the END of each month */
    SELECT
        month_start,
        SUM(cumulative_balance)                                                    AS total_balance_all_users
    FROM cum_balance
    GROUP BY month_start
),

prev_month_balances AS (   /* balance as of the 1st of each month = previous month’s total */
    SELECT
        month_start,
        LAG(total_balance_all_users) OVER (ORDER BY month_start)                   AS prev_month_balance
    FROM total_balances
)

SELECT
    TO_CHAR(month_start,'YYYY-MM')                                                 AS "month",
    GREATEST(prev_month_balance,0)                                                 AS "total_balance_previous_month"
FROM prev_month_balances
WHERE prev_month_balance IS NOT NULL        -- drop the very first (baseline) month
ORDER BY month_start ASC;