WITH
/* 1.  net change per customer per calendar day                         */
daily_net AS (
    SELECT
        "customer_id",
        "txn_date",
        SUM(
            CASE
                WHEN "txn_type" = 'deposit'  THEN  "txn_amount"
                ELSE                          - "txn_amount"
            END
        ) AS "net_change"
    FROM   "customer_transactions"
    GROUP  BY "customer_id", "txn_date"
),

/* 2.  earliest & latest transaction date for every customer           */
cust_range AS (
    SELECT
        "customer_id",
        MIN("txn_date") AS "start_date",
        MAX("txn_date") AS "end_date"
    FROM   "customer_transactions"
    GROUP  BY "customer_id"
),

/* 3.  build an unbroken calendar of dates per customer (recursive)    */
all_dates AS (
        SELECT
            "customer_id",
            "start_date" AS "cal_date",
            "end_date"
        FROM   cust_range
    UNION ALL
        SELECT
            "customer_id",
            date("cal_date", '+1 day'),
            "end_date"
        FROM   all_dates
        WHERE  "cal_date" < "end_date"
),

/* 4.  attach the net change (0 where no txn) to every calendar date   */
daily_flow AS (
    SELECT
        a."customer_id",
        a."cal_date"                   AS "txn_date",
        COALESCE(d."net_change", 0)    AS "net_change"
    FROM   all_dates  a
    LEFT   JOIN daily_net d
           ON d."customer_id" = a."customer_id"
          AND d."txn_date"   = a."cal_date"
),

/* 5.  running daily balance, capped at zero (no-negative rule)        */
daily_bal AS (
    SELECT
        "customer_id",
        "txn_date",
        MAX(0,
            SUM("net_change") OVER (
                PARTITION BY "customer_id"
                ORDER BY      "txn_date"
                ROWS BETWEEN  UNBOUNDED PRECEDING AND CURRENT ROW
            )
        ) AS "daily_balance"
    FROM   daily_flow
),

/* 6.  each customer’s monthly peak balance                            */
month_peak AS (
    SELECT
        "customer_id",
        strftime('%Y-%m', "txn_date") AS "month",
        MAX("daily_balance")          AS "peak_balance"
    FROM   daily_bal
    GROUP  BY "customer_id", "month"
)

/* 7.  sum the customer peaks to obtain the total peak per month       */
SELECT
    "month",
    SUM("peak_balance") AS "total_peak_balance_all_customers"
FROM   month_peak
GROUP  BY "month"
ORDER  BY "month";