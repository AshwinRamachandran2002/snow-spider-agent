WITH parsed AS (
    SELECT
        /* convert micro-second timestamp to UTC date */
        TO_DATE( TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) )                         AS "day",

        /* sign: +1 for mint (0x40c10f19…), ‑1 for burn (0x42966c68…) */
        CASE
            WHEN "input" ILIKE '0x40c10f19%' THEN  1
            ELSE                                   -1
        END
        *
        /* extract the 32-byte amount field, strip leading zeros, cast from hex,
           then scale from 6-decimals (USDC) to full tokens                     */
        TRY_TO_NUMBER(
            CONCAT(
                '0x',
                REGEXP_REPLACE(
                    SUBSTR(
                        "input",
                        CASE
                            WHEN "input" ILIKE '0x40c10f19%' THEN 151   /* mint  */
                            ELSE                                         23   /* burn */
                        END,
                        64
                    ),
                    '^0+'                    /* remove leading zeros   */
                )
            ),
            16                                /* hexadecimal → number  */
        ) / 1e6                               /* USDC has 6 decimals   */
        AS "signed_usdc"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'     -- USDC contract
      AND ("input" ILIKE '0x40c10f19%' OR "input" ILIKE '0x42966c68%')     -- mint or burn
      AND "block_timestamp"
            BETWEEN 1672531200000000    -- 2023-01-01 00:00:00 UTC
                AND 1704067199000000    -- 2023-12-31 23:59:59 UTC
)

SELECT
    "day",
    CONCAT(
        '$',
        TO_CHAR( SUM("signed_usdc"),
                 'FM999,999,999,990.00' )     -- format as USD
    ) AS "Δ Total Market Value"
FROM parsed
GROUP BY "day"
ORDER BY "day" DESC NULLS LAST;