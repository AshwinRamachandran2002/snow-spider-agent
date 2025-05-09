SELECT
    TO_CHAR(DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)), 'YYYY-MM-DD') AS "Date",
    TO_CHAR(
        SUM(
            CASE
                WHEN LEFT("input", 10) = '0x40c10f19' AND LENGTH("input") >= 138 THEN
                    COALESCE(TRY_TO_NUMBER('0x' || LTRIM(SUBSTR("input", 75, 64), '0'), 'X'), 0) / 1e6
                WHEN LEFT("input", 10) = '0x42966c68' AND LENGTH("input") >= 74 THEN
                    COALESCE(-TRY_TO_NUMBER('0x' || LTRIM(SUBSTR("input", 11, 64), '0'), 'X'), 0) / 1e6
                ELSE 0
            END
        ), 'FM$999,999,999,990.0000'
    ) AS "Δ Total Market Value"
FROM
    CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
WHERE
    (LEFT("input", 10) = '0x40c10f19' OR LEFT("input", 10) = '0x42966c68')
    AND "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
    AND "block_timestamp" >= 1672531200000000
    AND "block_timestamp" < 1704067200000000
GROUP BY
    "Date"
ORDER BY
    "Date" DESC NULLS LAST;