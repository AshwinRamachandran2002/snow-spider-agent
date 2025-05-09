WITH ordered_blocks AS (
    SELECT
        "number"                    AS "block_number",
        "timestamp"                 AS "ts_micro",
        ROW_NUMBER() OVER (
            ORDER BY "number"
        )                           AS "rn"
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE "timestamp" IS NOT NULL                  -- safeguard
),
consecutive_pairs AS (
    /* join each block to the immediately-preceding one */
    SELECT
        TO_DATE( TO_TIMESTAMP( a."ts_micro" / 1e6 ) )      AS "block_date",
        ( a."ts_micro" - b."ts_micro" ) / 1e6              AS "interval_seconds"   -- micro->seconds
    FROM ordered_blocks  a
    JOIN ordered_blocks  b
          ON a."rn" = b."rn" + 1                           -- previous row
)
SELECT
    "block_date",
    AVG( "interval_seconds" )        AS "avg_interval_seconds"
FROM   consecutive_pairs
WHERE  "block_date" BETWEEN '2023-01-01' AND '2023-12-31'   -- limit to 2023
GROUP  BY "block_date"
ORDER  BY "block_date"
LIMIT  10;                                                   -- first 10 calendar days