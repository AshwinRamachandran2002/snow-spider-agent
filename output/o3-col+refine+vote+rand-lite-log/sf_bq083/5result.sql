/*  Daily net change (mint – burn) in the market value of USDC for calendar-year 2023.
    – Mint selector  : 0x40c10f19  →  positive
    – Burn selector  : 0x42966c68  →  negative
    Amount is the last 32-byte (64-hex-char) chunk of `input`.
    USDC has 6 decimals, so divide by 1e6 and format in USD. */
SELECT
    "dt",
    TO_CHAR("net_usdc_change", 'FM$999,999,999,999,990.00') AS "Δ_Total_Market_Value_USD"
FROM (
    SELECT
        /*  Convert micro-seconds → date (UTC) */
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))                AS "dt",
        /*  Sum signed amounts (mint +, burn –) converted from hex → decimal → USDC */
        SUM(
            CASE
                WHEN "input" ILIKE '0x40c10f19%' THEN
                     TRY_TO_NUMBER(CONCAT('0x', RIGHT("input", 64)), 16) / 1e6
                ELSE /* burn selector 0x42966c68%               */
                    -TRY_TO_NUMBER(CONCAT('0x', RIGHT("input", 64)), 16) / 1e6
            END
        )                                                                 AS "net_usdc_change"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE  "to_address"    ILIKE '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
      AND ("input" ILIKE '0x40c10f19%' OR "input" ILIKE '0x42966c68%')
      /*  2023 only (micro-second timestamps) */
      AND  "block_timestamp" BETWEEN 1672531200000000 AND 1704067199000000
    GROUP  BY "dt"
)
ORDER BY "dt" DESC NULLS LAST;