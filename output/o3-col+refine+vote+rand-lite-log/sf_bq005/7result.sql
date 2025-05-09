/* Daily un-adjusted average inter-arrival time (in seconds) for Bitcoin blocks in 2023 */
WITH blocks_2023 AS (
    SELECT  "number",
            "timestamp",
            ROW_NUMBER() OVER (ORDER BY "timestamp") AS rn
    FROM    CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE   "timestamp" BETWEEN 1672531200000000   -- 2023-01-01 00:00:00 UTC (µs)
                          AND     1704067199000000   -- 2023-12-31 23:59:59 UTC (µs)
),
pairs AS (                       -- self-join consecutive blocks (skips the very first)
    SELECT  curr."timestamp"                                       AS curr_ts,
            (curr."timestamp" - prev."timestamp")/1e6             AS interval_sec
    FROM    blocks_2023  curr
    JOIN    blocks_2023  prev
           ON curr.rn = prev.rn + 1
)
SELECT  CAST(TO_TIMESTAMP(curr_ts/1000000) AS DATE)  AS block_date,
        AVG(interval_sec)                            AS avg_interval_sec
FROM    pairs
GROUP BY 1
ORDER BY 1
LIMIT 10;