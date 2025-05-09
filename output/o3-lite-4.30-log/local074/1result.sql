WITH
months AS (
    SELECT DISTINCT strftime('%Y-%m', "txn_date") AS month_year
    FROM "customer_transactions"
),
customers AS (
    SELECT DISTINCT "customer_id"
    FROM "customer_transactions"
),
calendar AS (
    SELECT  c."customer_id",
            m.month_year,
            date(m.month_year || '-01','start of month','+1 month','-1 day') AS month_end
    FROM    customers c
    CROSS   JOIN months    m
),
movements AS (
    SELECT  "customer_id",
            strftime('%Y-%m', "txn_date") AS month_year,
            SUM(
                CASE
                    WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                    WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                    ELSE 0
                END
            ) AS monthly_change
    FROM    "customer_transactions"
    GROUP   BY "customer_id", month_year
)
SELECT
    cal."customer_id"                                                    AS customer_id,
    cal.month_end                                                        AS month_end,
    ROUND(COALESCE(mv.monthly_change, 0), 4)                             AS monthly_change,
    ROUND(
        SUM(COALESCE(mv.monthly_change, 0)) OVER (
            PARTITION BY cal."customer_id"
            ORDER BY     cal.month_end
        ), 4
    )                                                                    AS closing_balance
FROM    calendar  cal
LEFT    JOIN movements mv
           ON  cal."customer_id" = mv."customer_id"
           AND cal.month_year   = mv.month_year
ORDER BY cal."customer_id", cal.month_end;