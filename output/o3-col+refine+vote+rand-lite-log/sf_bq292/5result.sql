/*  Monthly CoinJoin share (Txs, UTXOs, Volume) for Bitcoin since 2023-07-01 UTC
    CoinJoin heuristics
      – transaction has >2 outputs
      – at least two outputs have the same value ( COUNT(DISTINCT value) < COUNT(*) )
      – total output value ≤ transaction input value
*/

WITH
/* ---------------------------------------------------------------------- */
/* 1.  Aggregate every transaction’s output-side statistics              */
output_stats AS (
    SELECT
        "transaction_hash",
        COUNT(*)                       AS output_cnt,
        COUNT(DISTINCT "value")        AS distinct_value_cnt,
        SUM("value")                   AS total_output_value            -- satoshis
    FROM   CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    WHERE  "block_timestamp" >= 1688169600000000      -- ≥ 2023-07-01
    GROUP  BY "transaction_hash"
),

/* ---------------------------------------------------------------------- */
/* 2.  CoinJoin transactions that meet all three heuristic rules          */
coinjoin_tx AS (
    SELECT  o."transaction_hash"
    FROM    output_stats o
    JOIN    CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS" t
           ON t."hash" = o."transaction_hash"
    WHERE   o.output_cnt            >  2
      AND   o.distinct_value_cnt    <  o.output_cnt      -- ≥2 identical outputs
      AND   o.total_output_value    <= t."input_value"   -- spends own inputs
),

/* ---------------------------------------------------------------------- */
/* 3.  Monthly network-wide aggregates                                    */
network_month AS (
    SELECT
        TO_CHAR( TO_TIMESTAMP_NTZ( "block_timestamp" / 1e6 ), 'YYYY-MM') AS month,
        COUNT(*)                                   AS total_txns,
        SUM("input_count")                         AS total_utxos,
        SUM("input_value")                         AS total_volume
    FROM   CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    WHERE  "block_timestamp" >= 1688169600000000
    GROUP  BY TO_CHAR( TO_TIMESTAMP_NTZ( "block_timestamp" / 1e6 ), 'YYYY-MM')
),

/* ---------------------------------------------------------------------- */
/* 4.  Monthly aggregates restricted to CoinJoin txs                      */
coinjoin_month AS (
    SELECT
        TO_CHAR( TO_TIMESTAMP_NTZ( t."block_timestamp" / 1e6 ), 'YYYY-MM') AS month,
        COUNT(*)                                   AS coinjoin_txns,
        SUM(t."input_count")                       AS coinjoin_utxos,
        SUM(t."input_value")                       AS coinjoin_volume
    FROM   CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS" t
    JOIN   coinjoin_tx cj
           ON cj."transaction_hash" = t."hash"
    GROUP  BY TO_CHAR( TO_TIMESTAMP_NTZ( t."block_timestamp" / 1e6 ), 'YYYY-MM')
)

/* ---------------------------------------------------------------------- */
/* 5.  Final monthly percentage metrics                                   */
SELECT
    n.month,

    ROUND( 100 * cj.coinjoin_txns   / NULLIF( n.total_txns,   0), 4) AS txns_pct,
    ROUND( 100 * cj.coinjoin_utxos  / NULLIF( n.total_utxos,  0), 4) AS utxos_pct,
    ROUND( 100 * cj.coinjoin_volume / NULLIF( n.total_volume, 0), 4) AS volume_pct

FROM        network_month n
LEFT  JOIN  coinjoin_month cj ON cj.month = n.month
ORDER BY    n.month;