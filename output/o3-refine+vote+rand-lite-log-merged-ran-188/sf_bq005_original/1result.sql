/* Daily average Bitcoin block interval (seconds) for 2023 – first 10 days */
WITH ordered_blocks AS (
    SELECT
        "number",
        "timestamp",
        LAG("timestamp") OVER (ORDER BY "number")          AS "prev_timestamp"
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE "number" > 0                                     -- exclude genesis block
), block_intervals AS (
    SELECT
        DATE_TRUNC('DAY',
                   TO_TIMESTAMP_NTZ("timestamp" / 1e6))    AS "block_date",
        ("timestamp" - "prev_timestamp") / 1e6             AS "interval_seconds"
    FROM ordered_blocks
    WHERE "prev_timestamp" IS NOT NULL                     -- keep only rows with a predecessor
)
SELECT
    "block_date",
    AVG("interval_seconds") AS "avg_interval_seconds"
FROM block_intervals
WHERE "block_date" BETWEEN '2023-01-01' AND '2023-12-31'    -- restrict to 2023 (later‑block’s date)
GROUP BY "block_date"
ORDER BY "block_date"
LIMIT 10;