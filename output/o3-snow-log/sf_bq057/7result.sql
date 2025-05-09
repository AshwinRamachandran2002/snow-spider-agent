WITH tx_2021 AS (          -- all 2021 bitcoin transactions
    SELECT
        "hash",
        MONTH(TO_TIMESTAMP_NTZ("block_timestamp"/1e6))                    AS month,
        "input_value"::FLOAT                                              AS input_value,
        "output_value"::FLOAT                                             AS output_value,
        "input_count"::INTEGER                                            AS in_cnt,
        "output_count"::INTEGER                                           AS out_cnt
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE  "block_timestamp" BETWEEN 1609459200000000     -- 2021-01-01
                                 AND     1640995200000000  -- 2022-01-01
),                                                               
-- expand every output to detect equal-value outputs
outputs_expanded AS (
    SELECT  t."hash",
            VALUE:"value"::FLOAT  AS out_value
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t,
           LATERAL FLATTEN(input => t."outputs")
    WHERE  t."hash" IN (SELECT "hash" FROM tx_2021)
),                                                               
-- transactions with at least two identical-value outputs
tx_with_equal_outs AS (
    SELECT   "hash"
    FROM     outputs_expanded
    GROUP BY "hash"
    HAVING   COUNT(*) > COUNT(DISTINCT out_value)
),                                                               
-- apply CoinJoin definition
coinjoin_tx AS (
    SELECT  t.*
    FROM    tx_2021 t
    JOIN    tx_with_equal_outs e USING("hash")
    WHERE   t.out_cnt > 2
      AND   t.output_value <= t.input_value
),                                                               
-- monthly totals for all transactions
totals AS (
    SELECT month,
           COUNT(*)          AS total_tx,
           SUM(in_cnt)       AS total_inputs,
           SUM(out_cnt)      AS total_outputs,
           SUM(output_value) AS total_vol
    FROM   tx_2021
    GROUP  BY month
),                                                               
-- monthly totals for CoinJoin transactions
cj AS (
    SELECT month,
           COUNT(*)          AS cj_tx,
           SUM(in_cnt)       AS cj_inputs,
           SUM(out_cnt)      AS cj_outputs,
           SUM(output_value) AS cj_vol
    FROM   coinjoin_tx
    GROUP  BY month
),                                                               
-- percentages
metrics AS (
    SELECT  t.month,
            ROUND(100 * COALESCE(c.cj_tx,0)      / t.total_tx     ,1) AS pct_tx,
            ROUND(100 * (
                    COALESCE(c.cj_inputs,0) / t.total_inputs +
                    COALESCE(c.cj_outputs,0)/ t.total_outputs
                  ) / 2 ,1)                                            AS pct_utxos,
            ROUND(100 * COALESCE(c.cj_vol,0)     / t.total_vol    ,1) AS pct_vol
    FROM    totals t
    LEFT JOIN cj c USING(month)
)
SELECT month               AS highest_month,
       pct_tx,             -- % of all txs that are CoinJoin
       pct_utxos,          -- % of UTXOs in CoinJoin (avg of inputs & outputs)
       pct_vol             -- % of BTC volume in CoinJoin
FROM   metrics
ORDER  BY pct_vol DESC NULLS LAST
LIMIT  1;