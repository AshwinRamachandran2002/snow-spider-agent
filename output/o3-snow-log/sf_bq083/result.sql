/*  Daily market-value change (Δ) of USDC in 2023 (mints – burns)            */
WITH usdc_tx AS (            -- 1 ── Filter USDC mint / burn calls in 2023
    SELECT
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))             AS tx_date,
        CASE
            WHEN LOWER(SUBSTR("input", 1, 10)) = '0x40c10f19'
                 THEN  1                                           -- mint
            ELSE -1                                                -- burn
        END                                                        AS sign_flag,
        "input"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
      AND (LOWER("input") LIKE '0x40c10f19%' OR
           LOWER("input") LIKE '0x42966c68%')
      AND TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))
            BETWEEN '2023-01-01' AND '2023-12-31'
),
amounts AS (                 -- 2 ── Decode 64-hex chunk, convert, apply sign
    SELECT
        tx_date,
        sign_flag
        * COALESCE(
              TRY_TO_NUMBER(
                  LTRIM(
                      SUBSTR(
                          "input",
                          CASE WHEN sign_flag = 1 THEN 75 ELSE 11 END,   -- start
                          64                                              -- length
                      ),
                      '0'
                  ),
                  16                                                     -- hex base
              ),
              0
          ) / 1000000.0                                                  -- USDC (6 dp)
          AS delta_value
    FROM usdc_tx
)
-- 3 ── Aggregate by day and format in USD
SELECT
    tx_date                                               AS "Date",
    TO_CHAR(SUM(delta_value),
            'FM$999,999,999,999,999,990.00')              AS "Δ Total Market Value"
FROM amounts
GROUP BY tx_date
ORDER BY tx_date DESC NULLS LAST;