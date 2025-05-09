WITH "BLOCKS_2023" AS (   -- keep only blocks whose own timestamp lies in 2023
    SELECT
        "number",
        "timestamp"
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE TO_TIMESTAMP_NTZ("timestamp" / 1e6) >= '2023-01-01'
      AND TO_TIMESTAMP_NTZ("timestamp" / 1e6) <  '2024-01-01'
),
"ORDERED" AS (            -- attach previous‑block timestamp (consecutive by height)
    SELECT
        "number",
        "timestamp",
        LAG("timestamp") OVER (ORDER BY "number") AS "prev_ts"
    FROM "BLOCKS_2023"
),
"INTERVALS" AS (          -- seconds between consecutive blocks; drop first (genesis / null)
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("timestamp" / 1e6))                    AS "block_date",
        ("timestamp" - "prev_ts") / 1e6                                 AS "interval_sec"
    FROM "ORDERED"
    WHERE "prev_ts" IS NOT NULL
)
SELECT
    "block_date",
    AVG("interval_sec")     AS "avg_block_interval_seconds"
FROM "INTERVALS"
GROUP BY "block_date"
ORDER BY "block_date"
LIMIT 10;