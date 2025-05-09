/* 1.  Collect every (address, timestamp, value) pair from INPUTS and OUTPUTS,
       then retain only the transactions that happened in October 2017.        */
WITH base AS (
    SELECT *
    FROM (
        /* INPUT side ------------------------------------------------------- */
        SELECT
            f.value::STRING  AS "address",
            i."block_timestamp"        AS "ts",
            i."value"::NUMBER          AS "val"
        FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"  i,
             LATERAL FLATTEN(input => i."addresses") f
        
        UNION ALL
        
        /* OUTPUT side ------------------------------------------------------ */
        SELECT
            f.value::STRING  AS "address",
            o."block_timestamp"        AS "ts",
            o."value"::NUMBER          AS "val"
        FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS" o,
             LATERAL FLATTEN(input => o."addresses") f
    )
    /* October-2017 window (inclusive) */
    WHERE "ts" BETWEEN 1506816000000000 /* 2017-10-01 00:00:00 UTC */
                   AND 1509494400000000 /* 2017-10-31 23:59:59 UTC */
),

/* 2.  The very latest timestamp reached by any address within that month.    */
last_ts AS (
    SELECT MAX("ts") AS "max_ts" FROM base
),

/* 3.  All addresses whose final October-2017 transaction occurred exactly
       at that latest moment.                                                 */
addrs_at_max AS (
    SELECT DISTINCT b."address"
    FROM base b, last_ts
    WHERE b."ts" = last_ts."max_ts"
),

/* 4.  For those addresses, sum every October-2017 transaction value.         */
addr_totals AS (
    SELECT 
        b."address",
        SUM(b."val") AS "total_val"
    FROM base b
    WHERE b."address" IN (SELECT "address" FROM addrs_at_max)
    GROUP BY b."address"
)

/* 5.  Return the single address with the highest cumulative value.           */
SELECT
    "address",
    "total_val"
FROM addr_totals
ORDER BY "total_val" DESC NULLS LAST
LIMIT 1;