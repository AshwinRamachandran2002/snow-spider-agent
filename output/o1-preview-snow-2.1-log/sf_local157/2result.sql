WITH daily_volumes AS (
    SELECT
        TO_DATE("txn_date", 'DD-MM-YYYY') AS "Date",
        "ticker" AS "Ticker",
        SUM("quantity") AS "Daily_Volume"
    FROM
        BANK_SALES_TRADING.BANK_SALES_TRADING."BITCOIN_TRANSACTIONS"
    WHERE
        TO_DATE("txn_date", 'DD-MM-YYYY') BETWEEN '2021-08-01' AND '2021-08-10'
    GROUP BY
        TO_DATE("txn_date", 'DD-MM-YYYY'),
        "ticker"
),
daily_percentage_change AS (
    SELECT
        "Date",
        "Ticker",
        "Daily_Volume",
        LAG("Daily_Volume") OVER (PARTITION BY "Ticker" ORDER BY "Date") AS "Previous_Day_Volume"
    FROM
        daily_volumes
)
SELECT
    TO_CHAR("Date", 'YYYY-MM-DD') AS "Date",
    "Ticker",
    ROUND((( "Daily_Volume" - "Previous_Day_Volume" ) / "Previous_Day_Volume" ) * 100, 4) AS "Percentage_Change"
FROM
    daily_percentage_change
WHERE
    "Previous_Day_Volume" IS NOT NULL
ORDER BY
    "Date",
    "Ticker";