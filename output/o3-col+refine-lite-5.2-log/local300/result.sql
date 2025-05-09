WITH signed_txns AS (
    /* 1. Give every transaction a signed amount (+ for deposits, – for withdrawals) */
    SELECT
        "customer_id",
        "txn_date",
        CASE
            WHEN "txn_type" = 'deposit'                       THEN  1 * "txn_amount"
            WHEN "txn_type" IN ('withdrawal','withdraw')      THEN -1 * "txn_amount"
            ELSE 0
        END AS signed_amt
    FROM "customer_transactions"
),
daily_change AS (
    /* 2. Net change in balance per customer per day */
    SELECT
        "customer_id",
        "txn_date",
        SUM(signed_amt) AS net_change
    FROM signed_txns
    GROUP BY "customer_id","txn_date"
),
date_bounds AS (
    /* 3. Earliest and latest transaction dates for each customer */
    SELECT
        "customer_id",
        MIN("txn_date") AS start_date,
        MAX("txn_date") AS end_date
    FROM "customer_transactions"
    GROUP BY "customer_id"
),
calendar AS (
    /* 4. Build a complete day‑by‑day calendar for every customer */
    SELECT
        customer_id,
        start_date AS calendar_date,
        end_date
    FROM date_bounds

    UNION ALL

    SELECT
        customer_id,
        date(calendar_date,'+1 day') AS calendar_date,
        end_date
    FROM calendar
    WHERE calendar_date < end_date
),
joined AS (
    /* 5. Attach daily net changes to the calendar, using 0 when no txn happened */
    SELECT
        cal.customer_id,
        cal.calendar_date,
        COALESCE(dc.net_change,0) AS net_change
    FROM calendar cal
    LEFT JOIN daily_change dc
           ON cal.customer_id = dc."customer_id"
          AND cal.calendar_date = dc."txn_date"
),
running_bal AS (
    /* 6. Running balance per customer, day by day */
    SELECT
        customer_id,
        calendar_date,
        SUM(net_change) OVER (PARTITION BY customer_id
                              ORDER BY calendar_date) AS bal
    FROM joined
),
daily_balances AS (
    /* 7. Treat negative balances as zero */
    SELECT
        customer_id,
        calendar_date,
        CASE WHEN bal < 0 THEN 0 ELSE bal END AS daily_balance
    FROM running_bal
),
cust_month_max AS (
    /* 8. Highest daily balance each customer reached in every month */
    SELECT
        customer_id,
        substr(calendar_date,1,7)           AS month,          -- YYYY‑MM
        MAX(daily_balance)                  AS max_daily_balance
    FROM daily_balances
    GROUP BY customer_id, month
)
/* 9. Monthly total: sum of customers’ monthly max balances */
SELECT
    month,
    SUM(max_daily_balance) AS monthly_total_max_balance
FROM cust_month_max
GROUP BY month
ORDER BY month;