/*  Daily net change (mint – burn) of USDC supply in 2023                     */
/*  – Mint  : 0x40c10f19<addr><amount> (positive)                             */
/*  – Burn  : 0x42966c68<amount>          (negative)                          */
/*  – Unit  : USDC ‑ divide decoded amount by 1 000 000                       */

WITH usdc_raw AS (   --------------------------------------------------------+
    SELECT
        TO_DATE( TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) )        AS "dt",
        LOWER("input")                                              AS "input"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE  LOWER("to_address") = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
      AND ( "input" ILIKE '0x40c10f19%' OR "input" ILIKE '0x42966c68%' )
      AND TO_DATE( TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) )
          BETWEEN '2023-01-01' AND '2023-12-31'
), parsed AS (        --------------------------------------------------------+
    SELECT
        "dt",
        CASE WHEN "input" ILIKE '0x40c10f19%' THEN 'mint' ELSE 'burn' END AS "op",
        /* isolate 64-hex-char amount and strip leading zeros              */
        REGEXP_REPLACE(
            CASE
                WHEN "input" ILIKE '0x40c10f19%'
                     THEN SUBSTR("input", 75, 64)      /* after fn-sig+addr */
                ELSE SUBSTR("input", 11, 64)            /* after fn-sig      */
            END,
        '^0+','')                                                     AS "hex_amt"
    FROM   usdc_raw
), amounts AS (       --------------------------------------------------------+
    SELECT
        "dt",
        (CASE WHEN "op"='mint' THEN 1 ELSE -1 END) *
        /*  Hex → decimal using format mask, NULL -> 0                     */
        ( COALESCE(
              TRY_TO_NUMBER(
                  "hex_amt",
                  'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'  -- 64 X
              ), 0
          ) / 1e6 )                                                  AS delta_usd
    FROM   parsed
)
SELECT
    "dt"                                                               AS "date",
    TO_CHAR( SUM(delta_usd),
             'FM$999,999,999,999,999,990.00' )                         AS "Δ Total Market Value"
FROM   amounts
GROUP  BY "dt"
ORDER  BY "dt" DESC NULLS LAST;