WITH blocks_2023 AS (
    SELECT
        "number",
        "timestamp"
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE "number" > 0
      AND "timestamp" BETWEEN 1672531200000000  -- 2023‑01‑01 00:00:00 UTC
                         AND 1704067199999999   -- 2023‑12‑31 23:59:59.999999 UTC
), 
rn AS (
    SELECT
        "timestamp",
        ROW_NUMBER() OVER (ORDER BY "number") AS rn
    FROM blocks_2023
), 
paired AS (
    SELECT
        a."timestamp"  AS ts,
        b."timestamp"  AS next_ts
    FROM rn a
    JOIN rn b
      ON b.rn = a.rn + 1                       -- consecutive blocks
), 
diffs AS (
    SELECT
        TO_DATE(TO_TIMESTAMP(ts / 1000000))      AS date,
        (next_ts - ts) / 1000000.0               AS interval_sec
    FROM paired
)
SELECT
    date,
    ROUND(AVG(interval_sec), 4) AS unadjusted_avg_block_interval_seconds
FROM diffs
GROUP BY date
ORDER BY date
LIMIT 10;