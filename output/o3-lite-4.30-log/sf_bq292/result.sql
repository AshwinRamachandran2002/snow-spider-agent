/*--------------------------------------------------------------------
  Monthly CoinJoin statistics for Bitcoin beginning 2023‑07‑01
  CoinJoin definition
      • > 2 outputs
      • ≥ 2 identical‑value outputs
      • output_value ≤ input_value
      • non‑coinbase transaction
  Metrics returned (per month, 4‑decimal precision)
      coinjoin_tx_pct      : % of user transactions that are CoinJoins
      coinjoin_utxo_pct    : % of UTXOs (inputs + outputs) involved in
                              CoinJoins versus all network UTXOs
      coinjoin_volume_pct  : % of network volume (sum input_value) via
                              CoinJoins
---------------------------------------------------------------------*/
WITH
-- A) transactions in scope (since 2023‑07‑01)
tx_filtered AS (
    SELECT  "hash",
            "block_timestamp",
            "input_value",
            "output_value",
            "is_coinbase"
    FROM    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE   "block_timestamp" >= 1688169600000000        -- 2023‑07‑01 UTC
),
-- B) transactions that contain any duplicated output value
dupe_value_tx AS (
    SELECT  DISTINCT o."transaction_hash"
    FROM    CRYPTO.CRYPTO_BITCOIN.OUTPUTS o
    JOIN    tx_filtered              t ON t."hash" = o."transaction_hash"
    GROUP  BY o."transaction_hash", o."value"
    HAVING COUNT(*) > 1
),
-- C) number of outputs per transaction
output_cnt AS (
    SELECT  "transaction_hash",
            COUNT(*) AS output_cnt
    FROM    CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    GROUP  BY "transaction_hash"
),
-- D) final CoinJoin transaction set
coinjoin_tx AS (
    SELECT DISTINCT t."hash"
    FROM   tx_filtered t
    JOIN   dupe_value_tx d ON d."transaction_hash" = t."hash"
    JOIN   output_cnt   c ON c."transaction_hash" = t."hash"
    WHERE  c.output_cnt  > 2
      AND  t."is_coinbase" = FALSE
      AND  t."output_value" <= t."input_value"
),
/*------------------------------------------------------------
   Monthly aggregates
------------------------------------------------------------*/
-- 1) transaction counts & volume
month_tx AS (
    SELECT  DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp"/1e6)) AS month,
            COUNT(*)                                                     AS tx_all,
            SUM("input_value")                                           AS vol_all,
            SUM(CASE WHEN "hash" IN (SELECT "hash" FROM coinjoin_tx)
                     THEN 1 ELSE 0 END)                                  AS tx_cj,
            SUM(CASE WHEN "hash" IN (SELECT "hash" FROM coinjoin_tx)
                     THEN "input_value" ELSE 0 END)                      AS vol_cj
    FROM    tx_filtered
    WHERE   "is_coinbase" = FALSE
    GROUP  BY 1
),
-- 2) UTXO counts (inputs) for CoinJoin & all
month_inputs AS (
    SELECT  DATE_TRUNC('month', TO_TIMESTAMP_NTZ(t."block_timestamp"/1e6)) AS month,
            COUNT(*)                                                       AS inputs_all,
            SUM(CASE WHEN i."transaction_hash" IN (SELECT "hash" FROM coinjoin_tx)
                     THEN 1 ELSE 0 END)                                    AS inputs_cj
    FROM    CRYPTO.CRYPTO_BITCOIN.INPUTS i
    JOIN    tx_filtered                t ON t."hash" = i."transaction_hash"
    GROUP  BY 1
),
-- 3) UTXO counts (outputs) for CoinJoin & all
month_outputs AS (
    SELECT  DATE_TRUNC('month', TO_TIMESTAMP_NTZ(t."block_timestamp"/1e6)) AS month,
            COUNT(*)                                                       AS outputs_all,
            SUM(CASE WHEN o."transaction_hash" IN (SELECT "hash" FROM coinjoin_tx)
                     THEN 1 ELSE 0 END)                                    AS outputs_cj
    FROM    CRYPTO.CRYPTO_BITCOIN.OUTPUTS o
    JOIN    tx_filtered                t ON t."hash" = o."transaction_hash"
    GROUP  BY 1
)
SELECT
    mt.month,
    /* Transaction share */
    ROUND(mt.tx_cj * 100.0 / NULLIF(mt.tx_all,0), 4)                                           AS coinjoin_tx_pct,
    /* UTXO share: (cj inputs + cj outputs) / (all inputs + all outputs) */
    ROUND(
        (COALESCE(mi.inputs_cj ,0) + COALESCE(mo.outputs_cj ,0))
        * 100.0
        / NULLIF(COALESCE(mi.inputs_all,0) + COALESCE(mo.outputs_all,0), 0)
    , 4)                                                                                       AS coinjoin_utxo_pct,
    /* Volume share */
    ROUND(mt.vol_cj * 100.0 / NULLIF(mt.vol_all,0), 4)                                         AS coinjoin_volume_pct
FROM   month_tx     mt
LEFT   JOIN month_inputs  mi ON mt.month = mi.month
LEFT   JOIN month_outputs mo ON mt.month = mo.month
ORDER  BY mt.month;