WITH usdc_ops AS (
    SELECT
        /* date (UTC) from micro‑second timestamp */
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))                       AS "op_date",

        /* +1 for mint, ‑1 for burn */
        CASE
            WHEN LOWER("input") LIKE '0x40c10f19%' THEN  1
            ELSE                                         -1
        END                                                                            AS "sign",

        /* raw 32‑byte amount (hex, no 0x) */
        CASE
            /* mint: selector(8) + address(64) = 72  ⇒ start 75 (1‑based) */
            WHEN LOWER("input") LIKE '0x40c10f19%' THEN SUBSTR("input", 75, 64)
            /* burn: selector only */
            ELSE                                   SUBSTR("input", 11, 64)
        END                                                                            AS "amt_hex"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE LOWER("to_address") = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'         -- USDC
      AND ( LOWER("input") LIKE '0x40c10f19%'       /* mint  */
         OR LOWER("input") LIKE '0x42966c68%' )     /* burn  */
      AND TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))
            BETWEEN '2023-01-01' AND '2023-12-31'
),
parsed AS (
    SELECT
        "op_date",
        /* hex → number; if conversion fails (e.g., >38‑digit), treat as 0 */
        "sign" * (
            COALESCE(
                TRY_TO_NUMBER(
                    UPPER(
                        IFF(
                            REGEXP_REPLACE("amt_hex", '^0+', '') = '',
                            '0',
                            REGEXP_REPLACE("amt_hex", '^0+', '')
                        )
                    ),
                    16
                ),
                0
            ) / 1000000    /* scale: USDC has 6 decimals */
        )                                                                   AS "delta_value"
    FROM usdc_ops
)
SELECT
    "op_date"                                                            AS "date",
    CONCAT(
        '$',
        TO_CHAR(SUM("delta_value"), '999,999,999,999,990.00')
    )                                                                    AS "Δ Total Market Value"
FROM parsed
GROUP BY "op_date"
ORDER BY "op_date" DESC NULLS LAST;