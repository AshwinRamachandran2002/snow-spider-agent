WITH tx_oct AS (

    /* All INPUTS occurring in October 2017 */
    SELECT  
        addr.value::STRING                             AS "ADDRESS",
        inp."block_timestamp"                          AS "TS",
        inp."value"::NUMBER                            AS "VALUE"
    FROM  CRYPTO.CRYPTO_BITCOIN."INPUTS"  AS inp,
          LATERAL FLATTEN(input => inp."addresses")   AS addr

    UNION ALL
    
    /* All OUTPUTS occurring in October 2017 */
    SELECT  
        addr.value::STRING                             AS "ADDRESS",
        out."block_timestamp"                          AS "TS",
        out."value"::NUMBER                            AS "VALUE"
    FROM  CRYPTO.CRYPTO_BITCOIN."OUTPUTS" AS out,
          LATERAL FLATTEN(input => out."addresses")   AS addr
)
, tx_oct_filtered AS (
    /* keep only rows within October-2017 (timestamps are in micro-seconds) */
    SELECT *
    FROM   tx_oct
    WHERE  "TS" BETWEEN 1506816000000000  /* 2017-10-01 00:00:00 UTC */
                   AND 1509494399000000   /* 2017-10-31 23:59:59 UTC */
)
, per_address AS (
    /* latest tx-time and total value per address within Oct-2017 */
    SELECT
        "ADDRESS",
        MAX("TS")              AS "LATEST_TS",
        SUM("VALUE")           AS "TOTAL_VALUE"
    FROM   tx_oct_filtered
    GROUP  BY "ADDRESS"
)
, latest_date AS (
    /* the maximal latest-transaction timestamp among all addresses */
    SELECT MAX("LATEST_TS") AS "MAX_TS"
    FROM   per_address
)
, latest_candidates AS (
    /* addresses whose final tx occurred on that maximal date */
    SELECT  p.*
    FROM    per_address  p
    JOIN    latest_date  d
           ON p."LATEST_TS" = d."MAX_TS"
)
SELECT  "ADDRESS"
FROM    latest_candidates
ORDER BY "TOTAL_VALUE" DESC NULLS LAST
LIMIT 1;