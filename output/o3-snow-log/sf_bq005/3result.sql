WITH ALL_BLOCKS AS (          -- every bitcoin block with a running row–number
    SELECT
        "number"                                     AS block_num ,
        "timestamp"                                  AS ts_micro ,           -- micro-seconds since epoch
        TO_DATE( TO_TIMESTAMP_NTZ( "timestamp" / 1e6) )  AS block_date ,     -- UTC calendar date
        ROW_NUMBER() OVER (ORDER BY "number")        AS rn
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
),

PAIRWISE_INTERVALS AS (       -- self-join consecutive rows (rn vs. rn-1)
    SELECT
        cur.block_date ,                                    -- date of *later* block
        ( cur.ts_micro - prv.ts_micro ) / 1000000.0 AS interval_seconds
    FROM   ALL_BLOCKS  cur
    JOIN   ALL_BLOCKS  prv
           ON prv.rn = cur.rn - 1                           -- immediately-preceding block
),

DAILY_AVG_2023 AS (           -- average interval per day (no further adjustments)
    SELECT
        block_date ,
        AVG( interval_seconds ) AS avg_interval_seconds
    FROM   PAIRWISE_INTERVALS
    WHERE  block_date BETWEEN '2023-01-01' AND '2023-12-31' -- keep days in 2023
    GROUP  BY block_date
)

SELECT
    block_date ,
    avg_interval_seconds
FROM   DAILY_AVG_2023
ORDER  BY block_date
LIMIT  10;                         -- first 10 calendar days of 2023