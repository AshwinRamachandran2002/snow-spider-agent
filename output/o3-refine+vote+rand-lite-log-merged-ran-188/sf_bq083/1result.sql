/* Daily Δ market value (mint − burn) of USDC in 2023 */
SELECT
    TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))                     AS "event_day",
    TO_VARCHAR(                                                             -- pretty USD-style formatting
        SUM(
            CASE
                /* +  for mints (function selector 0x40c10f19) */
                WHEN "input" ILIKE '0x40c10f19%' THEN
                     TRY_TO_NUMBER(
                         COALESCE(
                             NULLIF( LTRIM( SUBSTR("input", 75, 64), '0'), '' ),
                             '0'
                         ),
                     16) / 1e6
                /* –  for burns (function selector 0x42966c68) */
                ELSE
                    -TRY_TO_NUMBER(
                         COALESCE(
                             NULLIF( LTRIM( SUBSTR("input", 11, 64), '0'), '' ),
                             '0'
                         ),
                     16) / 1e6
            END
        ),
        '999,999,999,999,990.000'                                          -- format mask
    )                                                                       AS "Δ_Total_Market_Value_USD"
FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
  AND (
        "input" ILIKE '0x40c10f19%'     -- mint
     OR "input" ILIKE '0x42966c68%'     -- burn
  )
  /* 2023-01-01 00:00 UTC  →  2023-12-31 23:59 UTC  (micro-seconds) */
  AND "block_timestamp" BETWEEN 1672531200000000 AND 1704067199000000
GROUP BY "event_day"
ORDER BY "event_day" DESC NULLS LAST;