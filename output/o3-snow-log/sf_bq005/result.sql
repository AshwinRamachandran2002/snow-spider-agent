WITH ordered_blocks AS (
    SELECT
        "number",
        "timestamp"                                              AS ts_micro,
        TO_DATE(DATEADD(second, "timestamp" / 1e6, '1970-01-01')) AS block_date,
        ( "timestamp"
          - LAG("timestamp") OVER (ORDER BY "number")
        ) / 1e6                                                 AS interval_seconds
    FROM
        CRYPTO.CRYPTO_BITCOIN.BLOCKS
),
intervals_2023 AS (
    SELECT
        block_date,
        interval_seconds
    FROM
        ordered_blocks
    WHERE
        block_date BETWEEN '2023-01-01' AND '2023-12-31'
        AND interval_seconds IS NOT NULL          -- exclude the genesis block
)
SELECT
    block_date,
    AVG(interval_seconds) AS avg_interval_seconds
FROM
    intervals_2023
GROUP BY
    block_date
ORDER BY
    block_date
LIMIT 10;