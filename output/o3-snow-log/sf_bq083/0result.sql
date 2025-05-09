/* Daily net change (mint – burn) of USDC market value (in USD) during 2023 */
WITH usdc_movements AS (          -------------------------------------------------
    SELECT
        DATE_TRUNC(                                   -- calendar day of the tx
            'day',
            TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)
        )                                   AS "date",

        CASE                                   -- +1 mint, -1 burn
            WHEN LEFT("input", 10) = '0x40c10f19' THEN  1
            ELSE                                     -1
        END                                AS "sign",

        /* 32-byte amount (hex) – skip fn-sig (+ addr for mint) */
        SUBSTRING(
            "input",
            CASE
                WHEN LEFT("input", 10) = '0x40c10f19' THEN 75   -- mint
                ELSE                                            -- burn
                11
            END,
            64
        )                                  AS "amount_hex"
    FROM  CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'        -- USDC
      AND LEFT("input", 10) IN ('0x40c10f19', '0x42966c68')                   -- mint|burn
      AND TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)
              BETWEEN '2023-01-01' AND '2023-12-31 23:59:59.999'
), --------------------------------------------------------------------------
amounts AS (                           -- convert hex → number (USDC units)
    SELECT
        "date",
        "sign",
        TRY_TO_NUMBER("amount_hex", 16) / 1e6   AS "amount_usdc"   -- 6-decimals
    FROM usdc_movements
)

SELECT
    "date",
    TO_CHAR(
        SUM("sign" * "amount_usdc"),
        'FM$999,999,999,999,999,999,999,990.00'
    )                           AS "Δ Total Market Value"
FROM   amounts
WHERE  "amount_usdc" IS NOT NULL            -- exclude bad parses
GROUP  BY "date"
ORDER  BY "date" DESC NULLS LAST;