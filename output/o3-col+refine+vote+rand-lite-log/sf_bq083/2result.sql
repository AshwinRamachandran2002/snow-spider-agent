/*  Daily net change (USD) in the supply of the USDC token during 2023
    –  mints  (selector 0x40c10f19) are treated as POSITIVE
    –  burns  (selector 0x42966c68) are treated as NEGATIVE
    Amounts are decoded from the `input` field, converted from the
    smallest unit (6-decimals) to full USDC, summed per-day and
    formatted as currency.                                                  */
WITH tx AS (
    SELECT
        /*  Calendar day (UTC)                                              */
        TO_DATE(TO_TIMESTAMP_LTZ("block_timestamp" / 1e6))          AS "day",

        /*  +tokens for mint, –tokens for burn                             */
        CASE
            /* ---------------------------  MINT  ------------------------ */
            WHEN "input" ILIKE '0x40c10f19%' THEN
                (
                    /* raw 32-byte amount starts at byte-offset 75          */
                    TRY_TO_NUMBER(
                        IFF(
                            LENGTH(LTRIM(SUBSTR("input", 75, 64), '0')) = 0,
                            '0',
                            CONCAT('0x', LTRIM(SUBSTR("input", 75, 64), '0'))
                        ),
                        16
                    )
                ) / 1e6          /* convert from 6-decimals to whole USDC  */

            /* ---------------------------  BURN  ------------------------ */
            WHEN "input" ILIKE '0x42966c68%' THEN
               -(
                    /* raw 32-byte amount starts at byte-offset 11          */
                    TRY_TO_NUMBER(
                        IFF(
                            LENGTH(LTRIM(SUBSTR("input", 11, 64), '0')) = 0,
                            '0',
                            CONCAT('0x', LTRIM(SUBSTR("input", 11, 64), '0'))
                        ),
                        16
                    )
                ) / 1e6

        END                                                         AS "delta_usdc"
    FROM CRYPTO.CRYPTO_ETHEREUM."TRANSACTIONS"
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'      -- USDC
      AND ("input" ILIKE '0x40c10f19%' OR "input" ILIKE '0x42966c68%')      -- mint / burn
      AND "block_timestamp" BETWEEN 1672531200000000                       -- 2023-01-01
                                AND 1704067199000000                       -- 2023-12-31
)

SELECT
    "day",
    /*  format summed change as USD (locale currency symbol ‘$’)            */
    TO_CHAR( SUM("delta_usdc"), 'L999,999,999,999,999.00' )  AS "Δ Total Market Value"
FROM tx
GROUP BY "day"
ORDER BY "day" DESC NULLS LAST;