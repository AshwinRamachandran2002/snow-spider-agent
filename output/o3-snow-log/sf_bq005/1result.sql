WITH blocks_with_prev AS (
    /* add the previous block’s timestamp for every Bitcoin block */
    SELECT
        "number"                                   AS "block_number",
        "timestamp"                                AS "ts_micro",
        LAG("timestamp") 
            OVER (ORDER BY "number")               AS "prev_ts_micro"
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
),
block_intervals_2023 AS (
    /* keep only rows that have a previous-block timestamp and whose
       CURRENT block falls inside the 2023 calendar year                */
    SELECT
        TO_DATE(TO_TIMESTAMP("ts_micro" / 1000000))                     AS "block_date",
        ("ts_micro" - "prev_ts_micro") / 1000000.0                      AS "interval_seconds"
    FROM blocks_with_prev
    WHERE "prev_ts_micro" IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP("ts_micro" / 1000000)) BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT
    "block_date",
    AVG("interval_seconds")                                             AS "avg_interval_seconds"
FROM block_intervals_2023
GROUP BY "block_date"
ORDER BY "block_date"
LIMIT 10;