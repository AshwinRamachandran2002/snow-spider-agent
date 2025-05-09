WITH october AS (   -- all October-2017 Bitcoin activity (inputs + outputs)
    SELECT  
        f.value::STRING           AS "address",
        o."block_timestamp"       AS "ts",
        o."value"                 AS "val"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS" o,
         LATERAL FLATTEN(input => o."addresses") f
    WHERE o."block_timestamp" BETWEEN 1506816000000000      -- 2017-10-01
                                 AND 1509494399000000       -- 2017-10-31 23:59:59
    UNION ALL
    SELECT  
        f.value::STRING,
        i."block_timestamp",
        i."value"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"  i,
         LATERAL FLATTEN(input => i."addresses") f
    WHERE i."block_timestamp" BETWEEN 1506816000000000
                                 AND 1509494399000000
),
last_seen AS (                      -- each address’ final Oct-17 timestamp
    SELECT "address",
           MAX("ts") AS "last_ts"
    FROM   october
    GROUP  BY "address"
),
latest_date AS (                    -- latest such timestamp in the month
    SELECT MAX("last_ts") AS "max_ts"
    FROM   last_seen
),
candidates AS (                     -- addresses whose final txn is on that date
    SELECT l."address"
    FROM   last_seen   l
    JOIN   latest_date d
           ON l."last_ts" = d."max_ts"
),
candidate_totals AS (               -- total Oct-17 value per such address
    SELECT o."address",
           SUM(o."val") AS total_value
    FROM   october o
    JOIN   candidates c
           ON o."address" = c."address"
    GROUP  BY o."address"
)
SELECT "address"
FROM   candidate_totals
ORDER  BY total_value DESC NULLS LAST
LIMIT 1;