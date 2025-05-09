WITH ordered AS (
    SELECT
        "number"                              AS block_number,
        "timestamp"                           AS ts_us,
        LEAD("timestamp") OVER (ORDER BY "number") AS next_ts_us
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE "number" > 0                          -- exclude genesis block
),
intervals AS (
    SELECT
        DATE_TRUNC('day',
                   TO_TIMESTAMP_NTZ(ts_us / 1000000.0)
                  )::DATE                      AS block_date,
        (next_ts_us - ts_us) / 1000000.0       AS interval_seconds
    FROM ordered
    WHERE next_ts_us IS NOT NULL               -- need a following block
      AND DATE_TRUNC('year',
                     TO_TIMESTAMP_NTZ(ts_us / 1000000.0)
                    ) = DATE '2023-01-01'      -- keep intervals whose earlier block is in 2023
)
SELECT
    block_date,
    AVG(interval_seconds) AS avg_interval_seconds
FROM intervals
GROUP BY block_date
ORDER BY block_date
LIMIT 10;