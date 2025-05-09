WITH DailyVolumes AS (
    SELECT 
        TO_DATE("txn_date", 'DD-MM-YYYY') AS "Date",
        "ticker" AS "Ticker",
        SUM("quantity") AS "TotalVolume"
    FROM 
        "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_TRANSACTIONS"
    WHERE 
        TO_DATE("txn_date", 'DD-MM-YYYY') BETWEEN TO_DATE('01-08-2021', 'DD-MM-YYYY') AND TO_DATE('10-08-2021', 'DD-MM-YYYY')
    GROUP BY 
        "Date", "Ticker"
)
SELECT 
    "Date",
    "Ticker",
    ROUND(
        (
            ("TotalVolume" - LAG("TotalVolume") OVER (PARTITION BY "Ticker" ORDER BY "Date")) 
            / NULLIF(LAG("TotalVolume") OVER (PARTITION BY "Ticker" ORDER BY "Date"), 0)
        ) * 100, 4
    ) AS "Percentage_Change"
FROM 
    DailyVolumes
ORDER BY
    "Date" ASC, "Ticker" ASC;