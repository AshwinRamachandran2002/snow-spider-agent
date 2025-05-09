WITH ordered_blocks AS (
    SELECT
        "number"                                              AS block_number,
        "timestamp"                                           AS ts_micro,
        LAG("timestamp") OVER (ORDER BY "number")             AS prev_ts_micro,
        TO_DATE(TO_TIMESTAMP_LTZ("timestamp" / 1000000))      AS block_date
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
),
intervals_2023 AS (
    SELECT
        block_date,
        (ts_micro - prev_ts_micro) / 1000000.0 AS interval_seconds   -- convert µs → seconds
    FROM ordered_blocks
    WHERE prev_ts_micro IS NOT NULL
      AND block_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT
    block_date                                AS "date",
    AVG(interval_seconds)                     AS "avg_interval_seconds"
FROM intervals_2023
GROUP BY block_date
ORDER BY block_date
LIMIT 10;