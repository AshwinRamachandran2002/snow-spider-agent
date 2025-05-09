/* ----------------------------------------------------------
   Monthly CoinJoin statistics for Bitcoin (since 2023-07-01)
   ----------------------------------------------------------
   CoinJoin definition for a transaction (tx):
     1. More than 2 outputs               (out_cnt  > 2)
     2. Total output value ≤ input value  (out_val ≤ in_val)
     3. At least two identical-value outputs
---------------------------------------------------------- */
WITH
/* ---------- aggregate inputs ---------- */
inputs_agg AS (
    SELECT
        "transaction_hash",
        SUM("value")                            AS in_val,
        COUNT(*)                                AS in_cnt,
        MIN("block_timestamp")                  AS ts      -- acts as tx-timestamp
    FROM   CRYPTO.CRYPTO_BITCOIN.INPUTS
    WHERE  "block_timestamp" >= 1688169600000000   -- ≥ 2023-07-01
    GROUP  BY "transaction_hash"
),

/* ---------- aggregate outputs ---------- */
outputs_agg AS (
    SELECT
        "transaction_hash",
        SUM("value")            AS out_val,
        COUNT(*)                AS out_cnt
    FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    WHERE  "block_timestamp" >= 1688169600000000
    GROUP  BY "transaction_hash"
),

/* ---------- detect identical-value outputs ---------- */
identical_outs AS (
    SELECT
        "transaction_hash",
        MAX(cnt_per_value) AS max_identical_outputs
    FROM (
        SELECT
            "transaction_hash",
            "value",
            COUNT(*) AS cnt_per_value
        FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS
        WHERE  "block_timestamp" >= 1688169600000000
        GROUP  BY "transaction_hash", "value"
    )
    GROUP BY "transaction_hash"
),

/* ---------- combine tx-level info & CoinJoin flag ---------- */
tx_level AS (
    SELECT
        i."transaction_hash",
        /* calendar month of the tx (UTC) */
        TO_CHAR(TO_TIMESTAMP_NTZ(i.ts/1e6),'YYYY-MM')      AS month,
        i.in_val,
        o.out_val,
        o.out_cnt,
        id.max_identical_outputs,
        /* CoinJoin classification */
        CASE
            WHEN o.out_cnt > 2
             AND o.out_val <= i.in_val
             AND id.max_identical_outputs > 1
            THEN 1 ELSE 0
        END                                               AS is_coinjoin
    FROM inputs_agg           i
    JOIN outputs_agg          o   USING ("transaction_hash")
    JOIN identical_outs       id  USING ("transaction_hash")
),

/* ---------- monthly transaction totals ---------- */
tx_monthly AS (
    SELECT
        month,
        COUNT(*)                                AS total_txs,
        SUM(is_coinjoin)                        AS coinjoin_txs,
        SUM(in_val)                             AS total_volume,
        SUM(CASE WHEN is_coinjoin=1 THEN in_val ELSE 0 END) AS coinjoin_volume
    FROM   tx_level
    GROUP  BY month
),

/* ---------- monthly UTXO creation totals ---------- */
utxo_monthly AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp"/1e6),'YYYY-MM') AS month,
        COUNT(*)                                                   AS total_utxos
    FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    WHERE  "block_timestamp" >= 1688169600000000
    GROUP  BY month
),

/* ---------- CoinJoin UTXOs per month ---------- */
cj_utxo_monthly AS (
    SELECT
        month,
        SUM(out_cnt) AS coinjoin_utxos
    FROM   tx_level
    WHERE  is_coinjoin = 1
    GROUP  BY month
)

/* ---------- final metrics ---------- */
SELECT
    m.month                                           AS "month",
    /* ---- percentage of transactions that are CoinJoins ---- */
    ROUND(100.0*m.coinjoin_txs / NULLIF(m.total_txs,0), 4)        AS "pct_coinjoin_transactions",
    /* ---- percentage of UTXOs created via CoinJoins ---- */
    ROUND(
        100.0*COALESCE(cu.coinjoin_utxos,0) /
        NULLIF(u.total_utxos,0), 4)                               AS "pct_coinjoin_utxos",
    /* ---- percentage of volume (inputs) in CoinJoins ---- */
    ROUND(100.0*m.coinjoin_volume / NULLIF(m.total_volume,0), 4)  AS "pct_coinjoin_volume"
FROM          tx_monthly          m
LEFT JOIN     utxo_monthly        u   USING (month)
LEFT JOIN     cj_utxo_monthly     cu  USING (month)
ORDER BY      m.month;