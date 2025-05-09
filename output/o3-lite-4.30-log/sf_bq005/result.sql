WITH ordered AS (
    SELECT
        "number",
        "timestamp",
        ROW_NUMBER() OVER (ORDER BY "number") AS rn
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE "number" > 0                       -- exclude genesis block
),
pairs AS (
    SELECT
        FLOOR(a."timestamp" / 86400 / 1000000)                          AS epoch_day,   -- days since 1970‑01‑01 (UTC)
        (b."timestamp" - a."timestamp") / 1000000.0                     AS gap_sec      -- interval in seconds
    FROM ordered a
    JOIN ordered  b
        ON b.rn = a.rn + 1                                              -- consecutive blocks
    WHERE a."timestamp" >= 1672531200000000                             -- 2023‑01‑01 00:00:00 UTC
      AND a."timestamp" <  1704067200000000                             -- 2024‑01‑01 00:00:00 UTC
),
daily AS (
    SELECT
        DATEADD(day, epoch_day, DATE '1970-01-01')                      AS date,
        AVG(gap_sec)                                                    AS avg_gap_sec
    FROM pairs
    GROUP BY epoch_day
)
SELECT
    TO_CHAR(date, 'YYYY-MM-DD')                                         AS date,
    ROUND(avg_gap_sec, 4)                                               AS unadjusted_avg_block_interval_seconds
FROM daily
ORDER BY date
LIMIT 10;