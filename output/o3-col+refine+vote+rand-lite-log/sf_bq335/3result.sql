/* Address whose final October-2017 transaction happened the latest,
   and (if more than one share that timestamp) has the greatest total
   value moved during the month                                              */
WITH io AS (  -- all October-2017 INPUT & OUTPUT rows, exploded by address
    SELECT
        f.value::STRING          AS "address",
        o."block_timestamp"      AS "ts",
        o."value"::NUMBER        AS "val"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS" o,
         LATERAL FLATTEN(INPUT => o."addresses") f
    WHERE o."block_timestamp" BETWEEN 1506816000000000   -- 01-Oct-2017 00:00 UTC
                                 AND     1509494399000000 -- 31-Oct-2017 23:59 UTC
         
    UNION ALL
    
    SELECT
        f.value::STRING          AS "address",
        i."block_timestamp"      AS "ts",
        i."value"::NUMBER        AS "val"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS" i,
         LATERAL FLATTEN(INPUT => i."addresses") f
    WHERE i."block_timestamp" BETWEEN 1506816000000000
                                 AND     1509494399000000
), per_addr AS (   -- last-seen timestamp and total value per address
    SELECT
        "address",
        MAX("ts")                AS "last_ts",
        SUM("val")               AS "total_value"
    FROM io
    GROUP BY "address"
), max_ts AS (      -- overall latest October timestamp reached
    SELECT MAX("last_ts") AS "latest_ts"
    FROM   per_addr
)
SELECT  p."address",
        p."last_ts"          AS "latest_oct_timestamp",
        p."total_value"      AS "oct_total_value"
FROM    per_addr  p
JOIN    max_ts    m
  ON    p."last_ts" = m."latest_ts"
ORDER BY p."total_value" DESC NULLS LAST
LIMIT 1;