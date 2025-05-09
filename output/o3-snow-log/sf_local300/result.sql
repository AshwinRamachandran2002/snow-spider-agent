WITH daily_net AS (  -- net movement for each customer-day
    SELECT
        "customer_id",
        TO_DATE("txn_date", 'YYYY-MM-DD') AS "txn_day",
        SUM(
            CASE
                WHEN LOWER("txn_type") = 'deposit' THEN "txn_amount"
                ELSE -1 * "txn_amount"
            END
        ) AS "net_change"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id", TO_DATE("txn_date", 'YYYY-MM-DD')
),

rng AS (  -- first and last txn dates per customer
    SELECT
        "customer_id",
        MIN(TO_DATE("txn_date", 'YYYY-MM-DD')) AS "first_day",
        MAX(TO_DATE("txn_date", 'YYYY-MM-DD')) AS "last_day"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id"
),

all_days AS (  -- generate every day in each customer’s range
    SELECT
        r."customer_id",
        DATEADD('day', g.seq, r."first_day") AS "calendar_day"
    FROM rng r
    JOIN LATERAL (
        SELECT SEQ4() AS seq
        FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    ) g
        ON DATEADD('day', g.seq, r."first_day") <= r."last_day"
),

joined AS (  -- attach daily net change; 0 when none
    SELECT
        d."customer_id",
        d."calendar_day",
        COALESCE(n."net_change", 0) AS "net_change"
    FROM all_days d
    LEFT JOIN daily_net n
        ON  d."customer_id" = n."customer_id"
        AND d."calendar_day" = n."txn_day"
),

running_bal AS (  -- cumulative balance, never below zero
    SELECT
        "customer_id",
        "calendar_day",
        GREATEST(
            0,
            SUM("net_change") OVER (
                PARTITION BY "customer_id"
                ORDER BY "calendar_day"
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )
        ) AS "daily_balance"
    FROM joined
),

monthly_max AS (  -- maximum daily balance each month per customer
    SELECT
        "customer_id",
        TO_CHAR("calendar_day", 'YYYY-MM') AS "month_yyyy_mm",
        MAX("daily_balance") AS "max_daily_balance_in_month"
    FROM running_bal
    GROUP BY "customer_id", TO_CHAR("calendar_day", 'YYYY-MM')
)

-- final result: sum of those maxima per month
SELECT
    "month_yyyy_mm",
    SUM("max_daily_balance_in_month") AS "monthly_total_peak_balance"
FROM monthly_max
GROUP BY "month_yyyy_mm"
ORDER BY "month_yyyy_mm";