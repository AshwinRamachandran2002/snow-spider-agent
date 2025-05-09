WITH ordered_blocks AS (
    SELECT
        "number",
        "timestamp",
        TO_DATE( TO_TIMESTAMP( "timestamp" / 1000000 ) )                   AS "block_date",
        LAG("timestamp") OVER (ORDER BY "number")                          AS "prev_timestamp"
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
),
block_intervals AS (
    SELECT
        "block_date",
        ( "timestamp" - "prev_timestamp" ) / 1000000.0                    AS "interval_seconds"
    FROM ordered_blocks
    WHERE "prev_timestamp" IS NOT NULL
      AND EXTRACT(year FROM "block_date") = 2023
)
SELECT
    "block_date",
    AVG("interval_seconds")                                               AS "avg_interval_seconds"
FROM block_intervals
GROUP BY "block_date"
ORDER BY "block_date"
LIMIT 10;