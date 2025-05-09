/*  Monthly CoinJoin share (transactions, UTXOs, and volume) for Bitcoin
    – since 2023‑07‑01.                                            */

WITH
/* ------------------------------------------------------------------ */
/* 1)  Transactions whose outputs contain at least one duplicated
       value – first requirement of (relaxed) CoinJoin definition.    */
dup_value_tx AS (
    SELECT DISTINCT
           o."transaction_hash"          -- candidate CoinJoin tx
    FROM   CRYPTO.CRYPTO_BITCOIN."OUTPUTS"  o
    GROUP  BY o."transaction_hash",
              o."value"
    HAVING COUNT(*) > 1                  -- duplicated output value
),

/* ------------------------------------------------------------------ */
/* 2)  CoinJoin transactions =                                   *
 *     – more than two outputs                                    *
 *     – total output ≤ total input                               *
 *     – at least one duplicated‑value output (above CTE)         */
coinjoin_tx AS (
    SELECT DISTINCT
           t."hash"
    FROM   CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"  t
    JOIN   dup_value_tx                         d
           ON d."transaction_hash" = t."hash"
    WHERE  t."output_count"  >  2
      AND  t."output_value" <= t."input_value"
      AND  t."block_timestamp" >= 1688169600000000      -- 2023‑07‑01 µs
),

/* ------------------------------------------------------------------ */
/* 3)  Base table: per‑transaction facts plus CoinJoin flag.          */
base AS (
    SELECT
        TO_CHAR(
          TO_TIMESTAMP(t."block_timestamp" / 1e6),      -- month string
          'YYYY-MM'
        )                                AS "month",
        t."hash",
        (t."input_count" + t."output_count") AS "utxos",
        t."input_value"                      AS "volume",
        CASE WHEN cj."hash" IS NOT NULL
             THEN 1
             ELSE 0
        END                                AS "is_cj"
    FROM   CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS" t
    LEFT  JOIN coinjoin_tx cj
           ON cj."hash" = t."hash"
    WHERE  t."block_timestamp" >= 1688169600000000       -- 2023‑07‑01 µs
)

/* ------------------------------------------------------------------ */
/* 4)  Monthly aggregation of CoinJoin shares.                        */
SELECT
    "month",
    ROUND( 100.0 * SUM( "is_cj")                           / COUNT(*)
         , 2)                              AS "pct_cj_tx",
    ROUND( 100.0 * SUM( CASE WHEN "is_cj"=1 THEN "utxos" END )
            / NULLIF( SUM("utxos"), 0 )
         , 2)                              AS "pct_cj_utxos",
    ROUND( 100.0 * SUM( CASE WHEN "is_cj"=1 THEN "volume" END )
            / NULLIF( SUM("volume"), 0 )
         , 2)                              AS "pct_cj_volume"
FROM   base
GROUP  BY "month"
ORDER  BY "month";