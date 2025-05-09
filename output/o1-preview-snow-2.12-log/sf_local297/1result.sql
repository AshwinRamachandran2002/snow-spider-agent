WITH monthly_net AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD')) AS "month",
        SUM(
            CASE
                WHEN "txn_type" = 'deposit' THEN "txn_amount"
                WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
                ELSE 0
            END
        ) AS "net_monthly_amount"
    FROM
        BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD'))
),
closing_balance AS (
    SELECT
        "customer_id",
        "month",
        SUM("net_monthly_amount") OVER (PARTITION BY "customer_id" ORDER BY "month") AS "closing_balance"
    FROM
        monthly_net
),
most_recent_month AS (
    SELECT MAX("month") AS "most_recent_month" FROM closing_balance
),
growth_rate_calc AS (
    SELECT
        cb."customer_id",
        cb."month",
        cb."closing_balance",
        LAG(cb."closing_balance") OVER (PARTITION BY cb."customer_id" ORDER BY cb."month") AS "previous_balance"
    FROM
        closing_balance cb
),
most_recent_growth_rate AS (
    SELECT
        grc."customer_id",
        CASE
            WHEN grc."previous_balance" IS NULL OR grc."previous_balance" = 0 THEN grc."closing_balance" * 100
            ELSE ((grc."closing_balance" - grc."previous_balance") / ABS(grc."previous_balance")) * 100
        END AS "growth_rate"
    FROM
        growth_rate_calc grc
    JOIN
        most_recent_month mrm
    ON
        grc."month" = mrm."most_recent_month"
)
SELECT
    ROUND((COUNT(CASE WHEN mrg."growth_rate" > 5 THEN 1 END) * 100.0 / (SELECT COUNT(DISTINCT "customer_id") FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS)), 4) AS "Percentage_of_customers"
FROM
    most_recent_growth_rate mrg
;