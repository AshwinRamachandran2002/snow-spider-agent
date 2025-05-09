WITH monthly_net AS (
    /* 1.  Net (+deposit, –withdrawal) for the first day of every month */
    SELECT
        "customer_id",
        date(substr("txn_date",1,7) || '-01')          AS "month_start",
        SUM(
            CASE
                 WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                 WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                 ELSE 0
            END
        )                                              AS "monthly_net"
    FROM   "customer_transactions"
    GROUP BY
        "customer_id",
        substr("txn_date",1,7)
),
closing_balance AS (
    /* 2.  Cumulative closing balance per customer */
    SELECT
        mn."customer_id",
        mn."month_start",
        SUM(mn."monthly_net") OVER (
            PARTITION BY mn."customer_id"
            ORDER BY      mn."month_start"
        )                                             AS "closing_balance"
    FROM   monthly_net mn
),
latest AS (
    /* 3.  Identify the most-recent month and preceding balance */
    SELECT
        cb.*,
        LAG(cb."closing_balance") OVER (
            PARTITION BY cb."customer_id"
            ORDER BY      cb."month_start"
        )                                            AS "prev_balance",
        ROW_NUMBER() OVER (
            PARTITION BY cb."customer_id"
            ORDER BY      cb."month_start" DESC
        )                                            AS rn
    FROM   closing_balance cb
),
growth AS (
    /* 4.  Compute growth rate for the latest month of every customer */
    SELECT
        l."customer_id",
        CASE
             WHEN COALESCE(l."prev_balance",0) = 0
                  THEN l."closing_balance"*100.0
             ELSE (l."closing_balance" - l."prev_balance")*100.0 /
                  ABS(l."prev_balance")
        END                                          AS "growth_rate"
    FROM   latest l
    WHERE  l.rn = 1
)
/* 5.  Percentage of customers whose latest growth rate > 5 % */
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN g."growth_rate" > 5 THEN 1 ELSE 0 END) /
        COUNT(*),
        4
    )                                               AS "pct_customers_growth_gt_5"
FROM growth g;