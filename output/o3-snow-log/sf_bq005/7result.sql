WITH ordered_blocks AS (
    SELECT
        "number"                         AS "block_number",
        "timestamp"                      AS "ts_micro",
        TO_DATE(TO_TIMESTAMP("timestamp" / 1000000)) AS "block_date",
        LAG("timestamp") OVER (ORDER BY "number")    AS "prev_ts_micro"
    FROM
        CRYPTO.CRYPTO_BITCOIN.BLOCKS
),
block_intervals AS (
    SELECT
        "block_date",
        ("ts_micro" - "prev_ts_micro") / 1000000.0 AS "interval_seconds"
    FROM
        ordered_blocks
    WHERE
        "prev_ts_micro" IS NOT NULL                      -- exclude the genesis block
        AND "block_date" BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT
    "block_date"                         AS "date",
    AVG("interval_seconds")              AS "avg_block_interval_seconds"
FROM
    block_intervals
GROUP BY
    "block_date"
ORDER BY
    "block_date"
LIMIT 10;