WITH monthly AS (
    /* 1. Net deposits (positive) and withdrawals (negative) per customer-month */
    SELECT
        "customer_id",
        substr("txn_date",1,7) || '-01'                           AS "month_start",
        SUM(CASE
                WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
            END)                                                  AS "monthly_net"
    FROM   "customer_transactions"
    GROUP  BY "customer_id", substr("txn_date",1,7)
), closing_balances AS (
    /* 2. Running sum to obtain the month-end (closing) balance */
    SELECT
        "customer_id",
        "month_start",
        SUM("monthly_net") OVER (PARTITION BY "customer_id"
                                 ORDER BY "month_start")          AS "closing_balance"
    FROM   monthly
), ranked AS (
    /* 3. Rank months (latest = rn 1) so we can compare last two */
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "customer_id"
                           ORDER BY "month_start" DESC)           AS rn
    FROM   closing_balances
), growth AS (
    /* 4. Compute most-recent growth rate */
    SELECT
        cur."customer_id",
        cur."closing_balance"                                     AS "latest_balance",
        prev."closing_balance"                                    AS "prev_balance",
        CASE
            WHEN prev."closing_balance" IS NULL
                 OR prev."closing_balance" = 0
                 THEN cur."closing_balance" * 100.0               -- previous zero → multiply by 100
            ELSE (cur."closing_balance" - prev."closing_balance")
                   * 100.0 / prev."closing_balance"
        END                                                      AS "growth_rate_pct"
    FROM   ranked  cur
    LEFT   JOIN ranked  prev
           ON  cur."customer_id" = prev."customer_id"
           AND cur.rn = 1
           AND prev.rn = 2
    WHERE  cur.rn = 1
)
/* 5. Percentage of customers whose most-recent growth rate exceeds 5 % */
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN "growth_rate_pct" > 5 THEN 1 ELSE 0 END)
              / COUNT(*),
        2
    ) AS "pct_customers_growth_gt_5pct"
FROM   growth;