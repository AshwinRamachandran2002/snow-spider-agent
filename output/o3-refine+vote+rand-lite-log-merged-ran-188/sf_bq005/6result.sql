WITH ordered AS (  -- chronologically number every Bitcoin block
    SELECT
        "number"                                          AS block_height,
        "timestamp"                                       AS ts_us,
        TO_DATE(TO_TIMESTAMP_NTZ("timestamp" / 1000000))  AS block_date,
        ROW_NUMBER() OVER (ORDER BY "number")             AS rn
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
),
paired AS (         -- pair each block with its immediate predecessor
    SELECT
        cur.block_date,
        (cur.ts_us - prev.ts_us) / 1000000.0              AS interval_seconds
    FROM ordered cur
    JOIN ordered prev
      ON cur.rn = prev.rn + 1
    WHERE cur.ts_us BETWEEN 1672531200000000  -- 2023-01-01
                       AND 1704067199000000  -- 2023-12-31
)
SELECT
    block_date,
    AVG(interval_seconds) AS avg_interval_seconds
FROM paired
GROUP BY block_date
ORDER BY block_date
LIMIT 10;