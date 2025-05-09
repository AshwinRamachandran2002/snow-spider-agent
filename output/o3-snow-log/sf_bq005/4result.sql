WITH block_seq AS (
    /* 1.  Pull every bitcoin block, order by block height, and
           grab the previous block’s timestamp to build inter-block intervals   */
    SELECT
        "number"                                                   AS block_number,
        "timestamp"                                                AS ts_micro,
        TO_TIMESTAMP_NTZ("timestamp" / 1000000)                    AS ts,
        LAG("timestamp")  OVER (ORDER BY "number")                 AS prev_ts_micro
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
), intervals_2023 AS (
    /* 2.  Keep only blocks whose TIMESTAMP lands in calendar-year 2023
           and whose previous-block timestamp is available (not genesis)       */
    SELECT
        CAST(ts AS DATE)                                           AS block_date,
        /* convert µs → seconds for the interval */
        (ts_micro  - prev_ts_micro) / 1e6                          AS interval_seconds
    FROM block_seq
    WHERE YEAR(ts) = 2023
      AND prev_ts_micro IS NOT NULL
)
SELECT
    block_date,
    AVG(interval_seconds) AS avg_interval_seconds
FROM intervals_2023
GROUP BY block_date
ORDER BY block_date
LIMIT 10;