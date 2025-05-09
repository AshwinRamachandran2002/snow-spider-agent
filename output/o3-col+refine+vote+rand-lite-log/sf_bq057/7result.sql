WITH block_2021 AS (          -- 2021 Bitcoin blocks with handy month field
    SELECT  "number"                       AS block_number ,
            "timestamp_month"              AS month_date
    FROM    CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE   "timestamp_month" BETWEEN '2021-01-01' AND '2021-12-01'
),

/* ---------- aggregate basic per-transaction facts (within 2021 only) ---------- */
out_agg AS (
    SELECT  o."transaction_hash"                          AS tx_hash ,
            COUNT(*)                                      AS n_out ,
            COUNT(DISTINCT o."value")                     AS n_out_dist ,
            SUM(o."value")                                AS sum_out
    FROM    CRYPTO.CRYPTO_BITCOIN.OUTPUTS  o
    JOIN    block_2021                    b ON b.block_number = o."block_number"
    GROUP BY o."transaction_hash"
),
in_agg  AS (
    SELECT  i."transaction_hash"                          AS tx_hash ,
            COUNT(*)                                      AS n_in ,
            SUM(i."value")                                AS sum_in
    FROM    CRYPTO.CRYPTO_BITCOIN.INPUTS   i
    JOIN    block_2021                    b ON b.block_number = i."block_number"
    GROUP BY i."transaction_hash"
),

/* -------------------------- identify CoinJoin txs ----------------------------- */
coinjoin AS (
    SELECT  o.tx_hash
    FROM    out_agg o
    JOIN    in_agg  i  ON i.tx_hash = o.tx_hash
    WHERE   o.n_out > 2                                  -- >2 outputs
      AND   o.n_out_dist < o.n_out                       -- repeated output value
      AND   o.sum_out     <= i.sum_in                    -- value preservation
),

/* -------------------- month lookup for every 2021 transaction ----------------- */
tx_month AS (
    SELECT  t."hash"         AS tx_hash ,
            b.month_date
    FROM    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t
    JOIN    block_2021                     b ON b.block_number = t."block_number"
),

/* ------------------- total-universe monthly aggregates ------------------------ */
tot_tx   AS (
    SELECT month_date, COUNT(*) AS total_tx
    FROM   tx_month
    GROUP  BY month_date
),
tot_in   AS (
    SELECT b.month_date, COUNT(*) AS total_inputs
    FROM   CRYPTO.CRYPTO_BITCOIN.INPUTS i
    JOIN   block_2021 b ON b.block_number = i."block_number"
    GROUP  BY b.month_date
),
tot_out  AS (
    SELECT b.month_date,
           COUNT(*)             AS total_outputs ,
           SUM(o."value")       AS total_value
    FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS o
    JOIN   block_2021 b ON b.block_number = o."block_number"
    GROUP  BY b.month_date
),

/* ---------------- CoinJoin-only monthly aggregates ---------------------------- */
cj_tx  AS (
    SELECT tm.month_date , COUNT(*) AS cj_tx
    FROM   tx_month tm
    JOIN   coinjoin cj ON cj.tx_hash = tm.tx_hash
    GROUP  BY tm.month_date
),
cj_in  AS (
    SELECT b.month_date , COUNT(*) AS cj_inputs
    FROM   CRYPTO.CRYPTO_BITCOIN.INPUTS i
    JOIN   coinjoin cj ON cj.tx_hash = i."transaction_hash"
    JOIN   block_2021 b ON b.block_number = i."block_number"
    GROUP  BY b.month_date
),
cj_out AS (
    SELECT b.month_date ,
           COUNT(*)       AS cj_outputs ,
           SUM(o."value") AS cj_value
    FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS o
    JOIN   coinjoin cj ON cj.tx_hash = o."transaction_hash"
    JOIN   block_2021 b ON b.block_number = o."block_number"
    GROUP  BY b.month_date
),

/* ------------------- gather everything & compute shares ----------------------- */
monthly AS (
    SELECT  t.month_date,
            t.total_tx,
            ti.total_inputs,
            to_out.total_outputs,
            to_out.total_value,
            COALESCE(ct.cj_tx     ,0) AS cj_tx,
            COALESCE(ci.cj_inputs ,0) AS cj_inputs,
            COALESCE(co.cj_outputs,0) AS cj_outputs,
            COALESCE(co.cj_value  ,0) AS cj_value
    FROM    tot_tx  t
    JOIN    tot_in  ti     ON ti.month_date   = t.month_date
    JOIN    tot_out to_out ON to_out.month_date = t.month_date
    LEFT JOIN cj_tx  ct    ON ct.month_date   = t.month_date
    LEFT JOIN cj_in  ci    ON ci.month_date   = t.month_date
    LEFT JOIN cj_out co    ON co.month_date   = t.month_date
),

scores AS (
    SELECT  MONTH(month_date)                                          AS month_number ,
            ROUND(100.0 * cj_tx        / NULLIF(total_tx     ,0) ,1)   AS pct_coinjoin_tx ,
            ROUND(100.0 * ( (cj_inputs / NULLIF(total_inputs ,0)) +
                            (cj_outputs/ NULLIF(total_outputs,0)) )/2 ,1) AS pct_coinjoin_utxos ,
            ROUND(100.0 * cj_value     / NULLIF(total_value  ,0) ,1)   AS pct_coinjoin_volume
    FROM    monthly
)

/* -------------------- month with highest CoinJoin volume share ---------------- */
SELECT *
FROM   scores
ORDER  BY pct_coinjoin_volume DESC NULLS LAST
LIMIT  1;