WITH balances AS (   -- 1. net movement (all users combined) per calendar month
    SELECT
        DATE(SUBSTR("txn_date",1,7) || '-01')              AS month_start,
        SUM(CASE
                WHEN "txn_type"='deposit'   THEN  "txn_amount"
                ELSE                              -1*"txn_amount"
            END)                                           AS net_movement
    FROM   "customer_transactions"
    GROUP  BY month_start
),
prev_tot AS (        -- 2. running cumulative *up to the PREVIOUS month*
    SELECT
        month_start,
        SUM(net_movement) OVER (
            ORDER BY month_start
            ROWS  BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        )                                                 AS prev_total
    FROM   balances
),
cleaned AS (         -- 3. replace negative balances with zero & drop baseline month
    SELECT
        month_start,
        CASE
            WHEN prev_total < 0 THEN 0
            ELSE                     prev_total
        END                                              AS prev_month_total
    FROM   prev_tot
    WHERE  prev_total IS NOT NULL                        -- remove very first month
)
SELECT
    month_start,          -- first day of month (YYYY-MM-01)
    prev_month_total      -- total balance carried into this month
FROM   cleaned
ORDER  BY month_start;