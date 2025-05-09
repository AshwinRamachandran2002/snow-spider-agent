WITH ordered_blocks AS (
    SELECT
        "number",
        "timestamp",
        LAG("timestamp") OVER (ORDER BY "number") AS "prev_timestamp"
    FROM
        CRYPTO.CRYPTO_BITCOIN.BLOCKS
),
block_intervals AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("timestamp" / 1e6))           AS "block_date",
        ("timestamp" - "prev_timestamp") / 1e6                 AS "interval_seconds"
    FROM
        ordered_blocks
    WHERE
        "prev_timestamp" IS NOT NULL          -- skip genesis block
)
SELECT
    "block_date",
    AVG("interval_seconds") AS "avg_interval_seconds"
FROM
    block_intervals
WHERE
    "block_date" BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY
    "block_date"
ORDER BY
    "block_date"
LIMIT 10;