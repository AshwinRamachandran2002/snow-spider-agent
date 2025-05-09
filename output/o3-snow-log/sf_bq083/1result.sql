/*  Daily Δ market value (USD) of USDC on Ethereum – 2023  */
WITH raw_tx AS (   -- 1. 2023 Mint / Burn txs sent to the USDC contract
    SELECT
        "block_timestamp",
        LOWER("input") AS input_hex
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE LOWER("to_address") = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
      AND TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))
          BETWEEN '2023-01-01' AND '2023-12-31'
      AND (input_hex LIKE '0x40c10f19%'   -- mint()
           OR input_hex LIKE '0x42966c68%') -- burn()
),
parsed AS (        -- 2. Extract amount, convert hex→dec safely, apply sign
    SELECT
        CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) AS DATE) AS tx_date,

        /* + for mint , − for burn */
        (CASE WHEN input_hex LIKE '0x40c10f19%' THEN 1 ELSE -1 END) *
        (
            COALESCE(
                TRY_TO_NUMBER(
                    /* take 32-byte hex argument, strip leading zeros; if empty use 0 */
                    IFF(
                        LTRIM(
                            SUBSTR(
                                input_hex,
                                CASE WHEN input_hex LIKE '0x40c10f19%' THEN 75 ELSE 11 END,
                                64
                            ),
                            '0'
                        ) = '',
                        '0',
                        LTRIM(
                            SUBSTR(
                                input_hex,
                                CASE WHEN input_hex LIKE '0x40c10f19%' THEN 75 ELSE 11 END,
                                64
                            ),
                            '0'
                        )
                    ),
                    16               -- base-16
                ),
                0        -- if overflow or bad hex, treat as 0 and skip
            ) / 1e6      -- USDC has six decimals
        ) AS delta_value
    FROM raw_tx
    WHERE delta_value IS NOT NULL    -- keep only successfully parsed rows
)
SELECT
    tx_date,
    TO_CHAR(SUM(delta_value), 'FM$999,999,999,999,990.00') AS "Δ Total Market Value"
FROM parsed
GROUP BY tx_date
ORDER BY tx_date DESC NULLS LAST;