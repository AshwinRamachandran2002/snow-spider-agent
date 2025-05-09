-- Daily average (unadjusted) Bitcoin block-intervals (in seconds) for 2023
WITH ordered_blocks AS (          -- all blocks except the genesis block
    SELECT  "number",
            "timestamp",
            TO_DATE( TO_TIMESTAMP_LTZ("timestamp"/1e6) )      AS d,   -- calendar day (UTC)
            ROW_NUMBER() OVER (ORDER BY "number")             AS rn   -- absolute order
    FROM    CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE   "number" > 0                                      -- skip genesis
),
pairs AS (                          -- successive-block pairs
    SELECT  a.d,
            (b."timestamp" - a."timestamp") / 1e6             AS diff_secs
    FROM    ordered_blocks a
    JOIN    ordered_blocks b
           ON  b.rn = a.rn + 1
)
SELECT  d                                   AS "date",
        AVG(diff_secs)                      AS "avg_block_interval_secs"
FROM    pairs
WHERE   d BETWEEN '2023-01-01' AND '2023-12-31'   -- keep only 2023 days
GROUP   BY d
ORDER   BY d
LIMIT   10;                                       -- first ten days