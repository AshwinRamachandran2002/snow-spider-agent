WITH blocks AS (   -- bring the raw block time to TIMESTAMP
    SELECT
        "number",
        TO_TIMESTAMP("timestamp" / 1e6)      AS "utc_ts"
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
),
with_intervals AS ( -- attach the previous block‑time to compute the gap
    SELECT
        "number",
        "utc_ts",
        CAST("utc_ts" AS DATE)                                        AS "block_date",
        DATEDIFF(
            second,
            LAG("utc_ts") OVER (ORDER BY "number"),
            "utc_ts"
        )                                                             AS "interval_seconds"
    FROM blocks
)
SELECT
    "block_date",
    AVG("interval_seconds")                                           AS "avg_interval_seconds"
FROM with_intervals
WHERE "block_date" BETWEEN '2023-01-01' AND '2023-12-31'
  AND "interval_seconds" IS NOT NULL          -- drop the very first (genesis) block
GROUP BY "block_date"
ORDER BY "block_date"
LIMIT 10;