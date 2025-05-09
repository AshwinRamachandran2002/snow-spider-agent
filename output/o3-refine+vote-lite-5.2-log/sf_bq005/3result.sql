WITH "BLOCKS_ALL" AS (
    SELECT
        "number"        AS "block_number",
        "timestamp"     AS "ts_micro"
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
),
"BLOCKS_PREV" AS (
    SELECT
        "block_number",
        TO_DATE( TO_TIMESTAMP( "ts_micro" / 1000000 ) )                   AS "block_date",
        "ts_micro",
        LAG( "ts_micro" ) OVER (ORDER BY "block_number")                  AS "prev_ts_micro"
    FROM "BLOCKS_ALL"
),
"INTERVALS_2023" AS (
    SELECT
        "block_date",
        ( "ts_micro" - "prev_ts_micro" ) / 1000000.0                      AS "interval_seconds"
    FROM "BLOCKS_PREV"
    WHERE "block_number" > 0                                              -- exclude genesis block
      AND "prev_ts_micro" IS NOT NULL
      AND "block_date" BETWEEN '2023-01-01' AND '2023-12-31'              -- keep blocks dated in 2023
)
SELECT
    "block_date",
    AVG( "interval_seconds" )                                             AS "avg_interval_seconds"
FROM "INTERVALS_2023"
GROUP BY "block_date"
ORDER BY "block_date"
LIMIT 10;