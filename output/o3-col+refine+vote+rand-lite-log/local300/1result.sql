WITH date_bounds AS (
    /* 1.  Find the first and last transaction date for every customer */
    SELECT 
        "customer_id",
        MIN("txn_date") AS "min_date",
        MAX("txn_date") AS "max_date"
    FROM "customer_transactions"
    GROUP BY "customer_id"
),
recursive_dates AS (
    /* 2.  Build a complete daily calendar for each customer 
            between their min and max dates                    */
    SELECT 
        "customer_id",
        "min_date" AS "calendar_date",
        "max_date"
    FROM date_bounds
    UNION ALL
    SELECT
        "customer_id",
        DATE("calendar_date", '+1 day'),
        "max_date"
    FROM recursive_dates
    WHERE "calendar_date" < "max_date"
),
daily_net AS (
    /* 3.  Net impact per customer per day  
            (deposits = +, all others = –)   */
    SELECT
        "customer_id",
        "txn_date",
        SUM(
            CASE 
                WHEN "txn_type" = 'deposit' THEN  "txn_amount"
                ELSE                          -1 * "txn_amount"
            END
        ) AS "net_change"
    FROM "customer_transactions"
    GROUP BY "customer_id", "txn_date"
),
calendar_with_net AS (
    /* 4.  Combine the calendar with the daily net figures,
            defaulting missing days to zero change             */
    SELECT
        d."customer_id",
        d."calendar_date",
        COALESCE(n."net_change", 0) AS "net_change"
    FROM recursive_dates d
    LEFT JOIN daily_net n
      ON d."customer_id"   = n."customer_id"
     AND d."calendar_date" = n."txn_date"
),
running_balance AS (
    /* 5.  Running balance per customer, resetting negatives to zero */
    SELECT
        "customer_id",
        "calendar_date",
        MAX(
            0,
            SUM("net_change")
            OVER (PARTITION BY "customer_id"
                  ORDER BY "calendar_date")
        ) AS "daily_balance"
    FROM calendar_with_net
),
monthly_max AS (
    /* 6.  Each customer’s maximum balance per month */
    SELECT
        "customer_id",
        STRFTIME('%Y-%m', "calendar_date") AS "month",
        MAX("daily_balance")               AS "max_daily_balance"
    FROM running_balance
    GROUP BY "customer_id", "month"
)
/* 7.  Sum customers’ monthly maxima to get the final monthly total */
SELECT
    "month",
    SUM("max_daily_balance") AS "monthly_total_max_balance"
FROM monthly_max
GROUP BY "month"
ORDER BY "month";