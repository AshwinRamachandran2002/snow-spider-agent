WITH Transactions AS (
    SELECT
        "customer_id",
        TO_DATE("txn_date", 'YYYY-MM-DD') AS "txn_date_parsed",
        CASE
            WHEN "txn_type" = 'deposit' THEN "txn_amount"
            WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
            ELSE 0
        END AS "signed_amount"
    FROM
        BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
CumulativeBalances AS (
    SELECT
        "customer_id",
        "txn_date_parsed",
        SUM("signed_amount") OVER (
            PARTITION BY "customer_id"
            ORDER BY "txn_date_parsed" NULLS LAST
            ROWS UNBOUNDED PRECEDING
        ) AS "cumulative_balance"
    FROM
        Transactions
),
Months AS (
    SELECT DISTINCT
        DATE_TRUNC('MONTH', "txn_date_parsed") AS "month"
    FROM
        Transactions
),
PreviousMonthEnds AS (
    SELECT
        "month",
        DATEADD(DAY, -1, "month") AS "prev_month_end"
    FROM
        Months
),
CustomerMonths AS (
    SELECT
        c."customer_id",
        pme."month",
        pme."prev_month_end"
    FROM
        (SELECT DISTINCT "customer_id" FROM Transactions) c
    CROSS JOIN
        PreviousMonthEnds pme
),
BalancesUpToPrevMonthEnd AS (
    SELECT
        cm."customer_id",
        cm."month",
        MAX(cb."txn_date_parsed") AS "last_txn_date"
    FROM
        CustomerMonths cm
    LEFT JOIN
        CumulativeBalances cb
    ON
        cm."customer_id" = cb."customer_id"
        AND cb."txn_date_parsed" <= cm."prev_month_end"
    GROUP BY
        cm."customer_id",
        cm."month"
),
AdjustedBalances AS (
    SELECT
        b."customer_id",
        b."month",
        CASE
            WHEN cb."cumulative_balance" < 0 OR cb."cumulative_balance" IS NULL THEN 0
            ELSE cb."cumulative_balance"
        END AS "adjusted_balance"
    FROM
        BalancesUpToPrevMonthEnd b
    LEFT JOIN
        CumulativeBalances cb
    ON
        b."customer_id" = cb."customer_id"
        AND b."last_txn_date" = cb."txn_date_parsed"
),
MonthlyTotalBalances AS (
    SELECT
        "month",
        SUM("adjusted_balance") AS "total_balance"
    FROM
        AdjustedBalances
    GROUP BY
        "month"
),
FinalResult AS (
    SELECT
        "month",
        "total_balance"
    FROM
        MonthlyTotalBalances
    WHERE
        "month" > (SELECT MIN("month") FROM MonthlyTotalBalances)
)
SELECT
    TO_CHAR("month", 'YYYY-MM') AS "Month",
    ROUND("total_balance", 4) AS "Total_Balance"
FROM
    FinalResult
ORDER BY
    "Month" NULLS LAST;