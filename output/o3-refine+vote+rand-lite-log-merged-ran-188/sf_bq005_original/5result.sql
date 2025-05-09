WITH btc_2023 AS (
    /* keep only bitcoin blocks whose timestamp (stored in µs) falls in 2023 */
    SELECT
        "number"                               AS block_height ,
        "timestamp"                            AS ts_micro ,
        TO_TIMESTAMP_NTZ("timestamp"/1000000)  AS ts_sec ,
        CAST(TO_TIMESTAMP_NTZ("timestamp"/1000000) AS DATE) AS blk_date
    FROM  CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE  TO_TIMESTAMP_NTZ("timestamp"/1000000) 
           BETWEEN '2023-01-01' AND '2023-12-31 23:59:59.999'
),
seq AS (
    /* attach the next‑block time‑stamp to each block that is inside 2023  */
    SELECT
        blk_date ,
        ts_micro ,
        LEAD(ts_micro) OVER (ORDER BY block_height) AS next_ts_micro
    FROM btc_2023
)
SELECT
    blk_date                                            AS "date",
    AVG( (next_ts_micro - ts_micro) / 1000000.0 )       AS avg_block_interval_seconds
FROM   seq
WHERE  next_ts_micro IS NOT NULL          -- drop the very last block whose successor is unknown
GROUP  BY blk_date
ORDER  BY blk_date
LIMIT  10;