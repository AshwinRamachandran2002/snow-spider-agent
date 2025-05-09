WITH daily_volumes AS (
    SELECT
        (substr("txn_date", 7, 4) || '-' || substr("txn_date", 4, 2) || '-' || substr("txn_date", 1, 2)) AS "Date",
        "ticker" AS "Ticker",
        SUM("quantity") AS "daily_volume"
    FROM "bitcoin_transactions"
    WHERE
        (substr("txn_date", 7, 4) || '-' || substr("txn_date", 4, 2) || '-' || substr("txn_date", 1, 2)) BETWEEN '2021-08-01' AND '2021-08-10'
    GROUP BY "Date", "Ticker"
),
daily_volumes_with_lag AS (
    SELECT
        "Date",
        "Ticker",
        "daily_volume",
        LAG("daily_volume") OVER (PARTITION BY "Ticker" ORDER BY "Date") AS "previous_day_volume"
    FROM daily_volumes
)
SELECT
    "Date",
    "Ticker",
    CASE 
        WHEN "previous_day_volume" IS NULL THEN NULL
        ELSE ROUND((("daily_volume" - "previous_day_volume") / "previous_day_volume") * 100.0, 4)
    END AS "Percentage_Change"
FROM daily_volumes_with_lag
ORDER BY "Date", "Ticker";