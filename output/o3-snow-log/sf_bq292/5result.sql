WITH tx AS (          -- pull Bitcoin txs from July-2023 onward (skip coinbase)
    SELECT
        "hash"                            AS tx_hash ,
        TO_TIMESTAMP("block_timestamp"/1000000)  AS ts ,
        DATE_TRUNC('month',TO_TIMESTAMP("block_timestamp"/1000000)) AS month ,
        "input_count"     ::NUMBER        AS in_cnt ,
        "output_count"    ::NUMBER        AS out_cnt ,
        "input_value"     ::NUMBER        AS in_val ,
        "output_value"    ::NUMBER        AS out_val ,
        "outputs"                           outputs
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE TO_TIMESTAMP("block_timestamp"/1000000) >= '2023-07-01'
      AND COALESCE("is_coinbase",FALSE)=FALSE
),
-- list every output value for every tx
out_vals AS (
    SELECT
        tx_hash ,
        value_object.value:"value"::NUMBER AS out_value_sat
    FROM tx ,
         LATERAL FLATTEN(input => outputs) AS value_object
),
-- transactions that have at least two identical-value outputs
dup_val_tx AS (
    SELECT tx_hash
    FROM out_vals
    GROUP BY tx_hash
    HAVING COUNT(*) <> COUNT(DISTINCT out_value_sat)      -- duplicate values exist
),
-- coinjoin flag per transaction
classified AS (
    SELECT
        t.* ,
        CASE
             WHEN out_cnt > 2
              AND out_val <= in_val
              AND t.tx_hash IN (SELECT tx_hash FROM dup_val_tx)
             THEN 1 ELSE 0
        END AS is_coinjoin
    FROM tx t
),
-- monthly aggregation
monthly AS (
    SELECT
        month ,
        COUNT(*)                                               AS total_tx ,
        SUM(is_coinjoin)                                       AS cj_tx ,
        SUM(in_cnt)                                            AS total_inputs ,
        SUM(out_cnt)                                           AS total_outputs ,
        SUM(CASE WHEN is_coinjoin=1 THEN in_cnt  END)          AS cj_inputs ,
        SUM(CASE WHEN is_coinjoin=1 THEN out_cnt END)          AS cj_outputs ,
        SUM(in_val)                                            AS total_volume ,
        SUM(CASE WHEN is_coinjoin=1 THEN in_val END)           AS cj_volume
    FROM classified
    GROUP BY month
)
SELECT
    month                                            AS "MONTH" ,
    ROUND(100.0*cj_tx          / NULLIF(total_tx        ,0),4) AS "PCT_CJ_TRANSACTIONS" ,
    ROUND(100.0*(
            (cj_inputs / NULLIF(total_inputs ,0)) +
            (cj_outputs/ NULLIF(total_outputs,0))
          )/2 ,4)                                    AS "PCT_CJ_UTXOS" ,
    ROUND(100.0*cj_volume      / NULLIF(total_volume    ,0),4) AS "PCT_CJ_VOLUME"
FROM monthly
ORDER BY month;