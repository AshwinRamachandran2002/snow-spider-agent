WITH usdc_tx AS (
    SELECT
        /* -------- block date (UTC) -------- */
        TO_DATE(
            DATE_TRUNC(
                'day',
                TO_TIMESTAMP("block_timestamp" / 1e6)          -- μs → s
            )
        )                                           AS "date",

        /* -------- signed amount -------- */
        CASE
            WHEN STARTSWITH("input", '0x40c10f19') THEN  1     -- mint
            ELSE                                              -1     -- burn
        END
        *
        (
            /* extract the 32-byte amount, convert from hex, scale 6 dp */
            COALESCE(
                TRY_TO_NUMBER(
                    SUBSTRING(
                        "input",
                        CASE
                            WHEN STARTSWITH("input", '0x40c10f19')
                                 THEN 75    -- 10 (sig) + 64 (addr) + 1
                            ELSE                 11    -- 10 (sig) + 1
                        END,
                        64
                    ),
                    16                -- base-16
                ),
                0
            ) / 1e6                  -- USDC decimals
        )                                           AS delta_usd
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE
        LOWER("to_address") = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'   -- USDC
        AND ( STARTSWITH("input", '0x40c10f19') OR STARTSWITH("input", '0x42966c68') )
        AND TO_DATE(
                DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6))
            ) BETWEEN '2023-01-01' AND '2023-12-31'
)

SELECT
    "date",
    TO_CHAR(
        SUM(delta_usd),
        'FM$999,999,999,999,990.00'
    ) AS "Δ Total Market Value"
FROM usdc_tx
GROUP BY "date"
ORDER BY "date" DESC NULLS LAST;