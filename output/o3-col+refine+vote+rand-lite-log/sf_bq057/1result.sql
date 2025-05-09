WITH tx_2021 AS (   -- every Bitcoin tx in 2021 (include outputs for CoinJoin test)
    SELECT
        "hash",
        YEAR(TO_TIMESTAMP_NTZ("block_timestamp"/1000000))              AS yr,
        MONTH(TO_TIMESTAMP_NTZ("block_timestamp"/1000000))             AS mo,
        "output_count",
        "input_count",
        "output_value",
        "input_value",
        "outputs"                                                      -- VARIANT column
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE  YEAR(TO_TIMESTAMP_NTZ("block_timestamp"/1000000)) = 2021
),

/*-----------------------------------------------------------
  CoinJoin definition (≥3 outputs, value-preserving, ≥2 equal
  output values)
-----------------------------------------------------------*/
coinjoin_tx AS (
    SELECT DISTINCT
           t."hash",
           t.yr,
           t.mo
    FROM   tx_2021 t,
           LATERAL FLATTEN(input => t."outputs") fo
    WHERE  t."output_count" > 2
      AND  t."output_value" <= t."input_value"
    QUALIFY COUNT(*) OVER (PARTITION BY t."hash",
                                       fo.value:"value"::NUMBER) > 1
),

/*-----------------------------------------------------------
  Monthly aggregates for ALL transactions
-----------------------------------------------------------*/
all_month AS (
    SELECT
        yr,
        mo,
        COUNT(*)                             AS total_tx,
        SUM("output_value")                  AS all_volume,
        SUM("input_count")                   AS total_inputs,
        SUM("output_count")                  AS total_outputs
    FROM   tx_2021
    GROUP  BY yr, mo
),

/*-----------------------------------------------------------
  Monthly aggregates for CoinJoin transactions
-----------------------------------------------------------*/
cj_month AS (
    SELECT
        t.yr,
        t.mo,
        COUNT(*)                             AS cj_tx,
        SUM(t."output_value")                AS cj_volume,
        SUM(t."input_count")                 AS cj_inputs,
        SUM(t."output_count")                AS cj_outputs
    FROM   tx_2021      t
    JOIN   coinjoin_tx  c  ON c."hash" = t."hash"
    GROUP  BY t.yr, t.mo
),

/*-----------------------------------------------------------
  Build UTXO counts once so we can aggregate
-----------------------------------------------------------*/
utxo_in  AS (SELECT "transaction_hash" AS h, COUNT(*) cnt FROM CRYPTO.CRYPTO_BITCOIN.INPUTS  GROUP BY h),
utxo_out AS (SELECT "transaction_hash" AS h, COUNT(*) cnt FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS GROUP BY h),

/* total UTXOs per month (all tx) */
utxo_all_mo AS (
    SELECT
        tx.yr,
        tx.mo,
        SUM(COALESCE(ui.cnt,0)) AS total_utxo_in,
        SUM(COALESCE(uo.cnt,0)) AS total_utxo_out
    FROM   tx_2021 tx
    LEFT  JOIN utxo_in  ui ON ui.h = tx."hash"
    LEFT  JOIN utxo_out uo ON uo.h = tx."hash"
    GROUP BY tx.yr, tx.mo
),

/* UTXOs that live inside CoinJoin txs */
utxo_cj_mo AS (
    SELECT
        tx.yr,
        tx.mo,
        SUM(COALESCE(ui.cnt,0)) AS cj_utxo_in,
        SUM(COALESCE(uo.cnt,0)) AS cj_utxo_out
    FROM   tx_2021 tx
    JOIN   coinjoin_tx cj ON cj."hash" = tx."hash"
    LEFT  JOIN utxo_in  ui ON ui.h = tx."hash"
    LEFT  JOIN utxo_out uo ON uo.h = tx."hash"
    GROUP BY tx.yr, tx.mo
),

/*-----------------------------------------------------------
  Combine all stats & convert to percentages
-----------------------------------------------------------*/
stats AS (
    SELECT
        a.mo                                                  AS month,
        /* % of transactions that are CoinJoins */
        ROUND( (cj.cj_tx       * 100.0) / a.total_tx, 1)      AS pct_transactions_cj,

        /* average of %inputs and %outputs that live in CJ */
        ROUND( ( (cj_u.cj_utxo_in  * 100.0) / NULLIF(u_all.total_utxo_in ,0)
               + (cj_u.cj_utxo_out * 100.0) / NULLIF(u_all.total_utxo_out,0) ) / 2
               , 1)                                           AS pct_utxos_cj,

        /* % of total BTC volume that flows through CJ txs */
        ROUND( (cj.cj_volume  * 100.0) / NULLIF(a.all_volume,0), 1)  AS pct_volume_cj
    FROM   all_month     a
    JOIN   cj_month      cj    ON cj.yr  = a.yr  AND cj.mo  = a.mo
    JOIN   utxo_all_mo   u_all ON u_all.yr = a.yr AND u_all.mo = a.mo
    JOIN   utxo_cj_mo    cj_u  ON cj_u.yr = a.yr AND cj_u.mo  = a.mo
)

/*-----------------------------------------------------------
  Pick the month with the highest % volume in CoinJoins
-----------------------------------------------------------*/
SELECT month,
       pct_transactions_cj,
       pct_utxos_cj,
       pct_volume_cj
FROM   stats
ORDER  BY pct_volume_cj DESC NULLS LAST
LIMIT 1;