WITH ordered_blocks AS (
    /* give every bitcoin block a contiguous row-number ordered by height */
    SELECT
        "number"                                              AS block_height ,
        "timestamp"                                           AS ts_micro ,
        ROW_NUMBER() OVER (ORDER BY "number")                 AS rn
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
),
paired_blocks AS (
    /* self-join consecutive rows (rn  -> rn-1) to get back-to-back blocks   */
    SELECT
        curr.ts_micro              AS curr_ts_micro ,
        prev.ts_micro              AS prev_ts_micro ,
        /* convert micro-seconds to DATE (UTC) using the newer block time)  */
        TO_DATE( TO_TIMESTAMP_NTZ(curr.ts_micro / 1e6) )  AS block_date ,
        /* interval in seconds between the two blocks                       */
        ( curr.ts_micro - prev.ts_micro ) / 1e6           AS interval_sec
    FROM ordered_blocks  curr
    JOIN ordered_blocks  prev
          ON prev.rn = curr.rn - 1              -- previous block
    /* keep only intervals whose LATER block fell inside calendar-year 2023 */
    WHERE YEAR( TO_TIMESTAMP_NTZ(curr.ts_micro / 1e6) ) = 2023
),
daily_avg AS (
    SELECT
        block_date ,
        AVG(interval_sec)  AS avg_interval_seconds
    FROM paired_blocks
    GROUP BY block_date
)
SELECT
    block_date ,
    avg_interval_seconds
FROM daily_avg
ORDER BY block_date
LIMIT 10;