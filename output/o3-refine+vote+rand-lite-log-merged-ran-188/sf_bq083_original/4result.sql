WITH parsed AS (                              -- 1) locate mint / burn txs
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) AS "date",       -- UTC day
        CASE
            WHEN LOWER("input") LIKE '0x40c10f19%' THEN  1                      -- mint  (+)
            ELSE                                      -1                        -- burn  (‑)
        END                                             AS sign,
        CASE                                                            -- 64‑hex amount
            WHEN LOWER("input") LIKE '0x40c10f19%'                           -- mint : 2nd param
                 THEN SUBSTRING("input", 75, 64)
            ELSE SUBSTRING("input", 11, 64)                                  -- burn : 1st param
        END                                             AS amt_hex
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'         -- USDC contract
      AND (  LOWER("input") LIKE '0x40c10f19%'          -- mint
          OR LOWER("input") LIKE '0x42966c68%' )        -- burn
      AND YEAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) = 2023          -- year 2023
),
deltas AS (                               -- 2) hex amount → decimal → sign
    SELECT
        "date",
        sign * (
            COALESCE(
                TRY_TO_NUMBER(                                   -- convert hex → number
                    REGEXP_REPLACE(amt_hex, '^0+', ''),          -- strip leading zeros
                    'HEX'
                ),
                0                                                -- if empty / NULL → 0
            ) / 1e6                                              -- USDC has 6 decimals
        ) AS delta_usd
    FROM parsed
)
SELECT                                    -- 3) daily net Δ market value
    "date",
    TO_CHAR(SUM(delta_usd), 'FM$999,999,999,999,999D00') AS "Δ Total Market Value"
FROM deltas
GROUP BY "date"
ORDER BY "date" DESC NULLS LAST;