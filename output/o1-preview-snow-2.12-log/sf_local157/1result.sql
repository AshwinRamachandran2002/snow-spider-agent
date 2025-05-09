WITH price_data AS (
    SELECT
        "ticker",
        TO_DATE("market_date", 'DD-MM-YYYY') AS "market_date",
        CASE
            WHEN "volume" LIKE '%K' THEN TO_NUMBER(REPLACE("volume", 'K', '')) * 1000
            WHEN "volume" LIKE '%M' THEN TO_NUMBER(REPLACE("volume", 'M', '')) * 1000000
            WHEN "volume" = '-' THEN 0
            ELSE TO_NUMBER("volume")
        END AS "volume_numeric"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_PRICES
),
volume_changes AS (
    SELECT
        pd."ticker",
        pd."market_date",
        pd."volume_numeric",
        LAG(NULLIF(pd."volume_numeric", 0)) IGNORE NULLS OVER (
            PARTITION BY pd."ticker"
            ORDER BY pd."market_date"
        ) AS "prev_volume"
    FROM price_data pd
)
SELECT
    "ticker",
    "market_date",
    ROUND(
        (("volume_numeric" - "prev_volume") / "prev_volume") * 100,
        4
    ) AS "percentage_volume_change"
FROM volume_changes
WHERE "market_date" BETWEEN TO_DATE('01-08-2021', 'DD-MM-YYYY') AND TO_DATE('10-08-2021', 'DD-MM-YYYY')
ORDER BY "ticker", "market_date";