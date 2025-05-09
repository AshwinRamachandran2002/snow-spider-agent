WITH io AS (
    /*  Combine all input-side and output-side transactions that occurred
        during October-2017 and explode the address arrays               */
    SELECT
        f.value::STRING               AS "address",
        i."value"                     AS "val",
        i."block_timestamp"           AS "block_ts"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS i,
         LATERAL FLATTEN(input => i."addresses") f
    WHERE i."block_timestamp" BETWEEN 1506816000000000 AND 1509494399000000

    UNION ALL

    SELECT
        f.value::STRING               AS "address",
        o."value"                     AS "val",
        o."block_timestamp"           AS "block_ts"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS o,
         LATERAL FLATTEN(input => o."addresses") f
    WHERE o."block_timestamp" BETWEEN 1506816000000000 AND 1509494399000000
),
per_addr AS (
    /*  For each address calculate its last-seen timestamp in Oct-2017
        and the total value moved during that month                     */
    SELECT
        "address",
        SUM("val")                    AS "total_value_oct17",
        MAX("block_ts")               AS "last_ts_oct17"
    FROM io
    GROUP BY "address"
)
SELECT
    "address",
    "total_value_oct17",
    "last_ts_oct17"
FROM per_addr
/*  Pick the address whose final transaction happened latest in the month;
    if several share that timestamp, return the one with the largest value */
ORDER BY "last_ts_oct17" DESC NULLS LAST,
         "total_value_oct17" DESC NULLS LAST
LIMIT 1;