WITH ordered AS (
    SELECT
        "number"                                               AS block_number,
        "timestamp"                                            AS ts_us,                                    -- micro-seconds
        DATE_TRUNC('day', TO_TIMESTAMP_NTZ("timestamp"/1e6))   AS block_date,                               -- UTC day
        LAG("timestamp") OVER (ORDER BY "number")              AS prev_ts_us                                -- preceding block
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE "timestamp" IS NOT NULL                              -- safeguard
),
intervals AS (
    /*  interval (s) between this block and its immediate predecessor            */
    SELECT
        block_date,
        (ts_us - prev_ts_us)/1e6                                AS interval_seconds
    FROM ordered
    WHERE prev_ts_us IS NOT NULL                                -- exclude genesis
)
SELECT
    block_date                                AS "DATE",
    AVG(interval_seconds)                     AS "AVG_BLOCK_INTERVAL_SECONDS"
FROM intervals
WHERE block_date BETWEEN TO_DATE('2023-01-01') AND TO_DATE('2023-12-31')  -- year 2023
GROUP BY block_date
ORDER BY block_date
LIMIT 10;