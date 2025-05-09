/*  Daily net change (mint – burn) in the market value of USDC on Ethereum for 2023  */
WITH usdc_transfers AS (
    SELECT
        /*  Convert micro-seconds → timestamp → date (UTC) */
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))                        AS "date",

        /*  +1 for mint, –1 for burn  */
        CASE
            WHEN "input" ILIKE '0x40c10f19%' THEN  1
            ELSE                                   -1
        END                                                                   AS "sgn",

        /* ------------------------------------------------------------
           Amount extraction
           ------------------------------------------------------------
           1. Take the last 64 hex chars of the input.
           2. Strip leading zeros.
           3. Convert the remaining hex string → NUMBER (base-16).
           4. Divide by 1 000 000 to go from 6-dec USDC units → whole USDC.
        */
        COALESCE(
            TRY_TO_NUMBER(
                REGEXP_REPLACE(RIGHT("input", 64), '^0+', ''),   -- hex w/out leading zeros
                16                                               -- base-16 → decimal
            ),
            0
        ) / 1e6                                                 AS "amount_usdc"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'  -- USDC contract
      AND "block_timestamp" BETWEEN 1672531200000000                   -- 2023-01-01 00:00:00 UTC
                              AND 1704067199000000                   -- 2023-12-31 23:59:59 UTC
      AND ( "input" ILIKE '0x40c10f19%'   -- mint
         OR "input" ILIKE '0x42966c68%' ) -- burn
)

SELECT
    "date",
    CONCAT(
        '$',
        TO_CHAR(
            SUM("sgn" * "amount_usdc"),
            'FM999,999,999,999,990.00'
        )
    ) AS "Δ Total Market Value"
FROM usdc_transfers
GROUP BY "date"
ORDER BY "date" DESC NULLS LAST;