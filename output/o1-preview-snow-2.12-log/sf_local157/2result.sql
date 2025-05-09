SELECT
    c1."ticker",
    TO_CHAR(c1."market_date", 'DD-MM-YYYY') AS "market_date",
    CASE
        WHEN c1."volume_numeric" = 0 OR c0."volume_numeric" = 0 THEN NULL
        ELSE ROUND(((c1."volume_numeric" - c0."volume_numeric") / c0."volume_numeric") * 100, 4)
    END AS "percentage_volume_change"
FROM
    (
        SELECT
            "ticker",
            TO_DATE("market_date", 'DD-MM-YYYY') AS "market_date",
            CASE
                WHEN "volume" = '-' THEN 0
                WHEN RIGHT("volume", 1) = 'K' THEN TO_NUMBER(SUBSTR("volume", 1, LENGTH("volume") - 1)) * 1000
                WHEN RIGHT("volume", 1) = 'M' THEN TO_NUMBER(SUBSTR("volume", 1, LENGTH("volume") - 1)) * 1000000
                ELSE TO_NUMBER("volume")
            END AS "volume_numeric"
        FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_PRICES"
    ) c1
LEFT JOIN
    (
        SELECT
            "ticker",
            TO_DATE("market_date", 'DD-MM-YYYY') AS "market_date",
            CASE
                WHEN "volume" = '-' THEN 0
                WHEN RIGHT("volume", 1) = 'K' THEN TO_NUMBER(SUBSTR("volume", 1, LENGTH("volume") - 1)) * 1000
                WHEN RIGHT("volume", 1) = 'M' THEN TO_NUMBER(SUBSTR("volume", 1, LENGTH("volume") - 1)) * 1000000
                ELSE TO_NUMBER("volume")
            END AS "volume_numeric"
        FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_PRICES"
    ) c0
ON c1."ticker" = c0."ticker" AND c1."market_date" = DATEADD('day', 1, c0."market_date")
WHERE 
    c1."market_date" BETWEEN TO_DATE('01-08-2021', 'DD-MM-YYYY') AND TO_DATE('10-08-2021', 'DD-MM-YYYY')
    AND c0."volume_numeric" <> 0
ORDER BY
    c1."ticker", c1."market_date";