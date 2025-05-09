WITH usdc_tx AS (      /* 2023 USDC mint / burn transactions on Ethereum */
    SELECT
        TO_DATE( TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) )                         AS "dt",
        CASE WHEN "input" LIKE '0x40c10f19%' THEN  1 ELSE -1 END                     AS "sgn",
        CASE
              WHEN "input" LIKE '0x40c10f19%' THEN SUBSTR("input", 75 , 64)          /* mint  */
              ELSE                                 SUBSTR("input", 11 , 64)          /* burn  */
        END                                                                          AS "amt_hex"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE  LOWER("to_address") = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
      AND  ("input" LIKE '0x40c10f19%' OR "input" LIKE '0x42966c68%')
      AND  TO_DATE( TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) )
                BETWEEN '2023-01-01' AND '2023-12-31'
)

, decoded AS (
    SELECT
        "dt",
        "sgn" *
        COALESCE(
            TRY_TO_NUMBER(        /* hex → decimal; NULL → 0 */
                IFF("amt_hex" = RPAD('0',64,'0'), NULL, "amt_hex") , 16
            )
        , 0 ) / 1e6                                                  AS "delta_usd"     -- convert to whole USDC
    FROM usdc_tx
)

SELECT
    "dt"                                                             AS "DATE",
    TO_CHAR( SUM("delta_usd") , 'FM$999,999,999,999,990.00' )        AS "Δ Total Market Value"
FROM decoded
GROUP BY "dt"
ORDER BY "dt" DESC NULLS LAST;