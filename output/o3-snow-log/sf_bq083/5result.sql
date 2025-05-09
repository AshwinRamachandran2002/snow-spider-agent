/*  Daily net change (mint – burn) in USDC circulation during 2023              */
WITH relevant_tx AS (             -- 2023 mint / burn calls to USDC contract
    SELECT
        DATE_TRUNC(
            'DAY',
            TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)
        )                                        AS "day",
        CASE
            WHEN LOWER("input") LIKE '0x40c10f19%' THEN  1   -- mint
            WHEN LOWER("input") LIKE '0x42966c68%' THEN -1   -- burn
        END                                        AS "sign",
        LOWER("input")                             AS "input"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE  LOWER("to_address") = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
       AND "block_timestamp" BETWEEN 1672531200000000 AND 1704067199999999
       AND ( LOWER("input") LIKE '0x40c10f19%' OR LOWER("input") LIKE '0x42966c68%' )
),
amounts AS (                       -- extract 32-byte amount hex
    SELECT
        "day",
        "sign",
        CASE
            WHEN "sign" = 1
                 THEN SUBSTR("input", 75, 64)      -- mint: second parameter
            ELSE SUBSTR("input", 11, 64)           -- burn: first parameter
        END                                        AS "hex_amount"
    FROM relevant_tx
),
numeric AS (                       -- hex → decimal, scale, apply sign
    SELECT
        "day",
        (
            COALESCE(
                TRY_TO_NUMBER("hex_amount", 16),   -- base-16 conversion
                0
            ) / 1000000.0                          -- USDC has 6 decimals
        ) * "sign"                                AS "delta_usdc"
    FROM amounts
)

SELECT
    "day"                                                             AS "DATE",
    TO_CHAR(
        SUM("delta_usdc"),
        'FM$999,999,999,999,999,999,990.00'
    )                                                                 AS "Δ Total Market Value"
FROM numeric
GROUP BY "day"
ORDER BY "day" DESC NULLS LAST;