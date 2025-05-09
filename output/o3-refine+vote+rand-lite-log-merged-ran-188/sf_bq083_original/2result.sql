/* Daily net change (mint – burn) of USDC outstanding supply in 2023 */
WITH txs AS (          -- mint / burn calls sent to the USDC contract
    SELECT
        DATE_TRUNC(
            'DAY',
            TO_TIMESTAMP("block_timestamp" / 1e6)        -- µs → s
        )                                         AS "dt",
        CASE
            WHEN LOWER("input") LIKE '0x40c10f19%' THEN  1   -- mint()
            ELSE                                            -1   -- burn()
        END                                         AS sign,
        /* 64‑hex‑char amount argument (2nd for mint, 1st for burn) */
        SUBSTR(
            "input",
            CASE
                WHEN LOWER("input") LIKE '0x40c10f19%' THEN 75    -- 0x + 8 + 64
                ELSE                                               11   -- 0x + 8
            END,
            64
        )                                         AS amt_hex
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE
          "block_timestamp" BETWEEN 1672531200000000       -- 2023‑01‑01
                               AND     1704067200000000    -- 2024‑01‑01
      AND LOWER("to_address")
            = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48' -- USDC contract
      AND ( LOWER("input") LIKE '0x40c10f19%'   -- mint()
         OR LOWER("input") LIKE '0x42966c68%' ) -- burn()
),
numbers AS (          -- hex → decimal, scale to units, apply sign
    SELECT
        "dt",
        sign
        * COALESCE(
              TRY_TO_NUMBER(                         -- base‑16 conversion
                  REGEXP_REPLACE(amt_hex, '^0+', ''), 16
              ),
              0
          ) / 1e6                                    -- 6‑decimals → units
          AS delta_value
    FROM txs
)
SELECT
    "dt"                                            AS "DATE",
    TO_CHAR(
        SUM(delta_value),
        'FM$999,999,999,999,999,990.00'
    )                                               AS "Δ Total Market Value"
FROM numbers
GROUP BY "dt"
ORDER BY "dt" DESC NULLS LAST;