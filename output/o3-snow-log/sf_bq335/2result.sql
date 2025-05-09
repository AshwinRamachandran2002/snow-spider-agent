WITH monthly_txns AS (
    /* 1.  Collect every (address , transaction-date , value) pair that appears
          either as an input or an output during October-2017                */
    SELECT  
        el.value::STRING                                   AS "ADDRESS",
        DATE_TRUNC('day'
          ,TO_TIMESTAMP_NTZ("block_timestamp"/1000000))    AS "TXN_DATE",
        "value"::NUMBER                                    AS "AMOUNT"
    FROM  CRYPTO.CRYPTO_BITCOIN."INPUTS",
          LATERAL FLATTEN(input => "addresses") el
    WHERE "block_timestamp" >= 1506816000000000  -- 2017-10-01 00:00:00 UTC
      AND "block_timestamp" <  1509494400000000  -- 2017-11-01 00:00:00 UTC

    UNION ALL

    SELECT  
        el.value::STRING                                   AS "ADDRESS",
        DATE_TRUNC('day'
          ,TO_TIMESTAMP_NTZ("block_timestamp"/1000000))    AS "TXN_DATE",
        "value"::NUMBER                                    AS "AMOUNT"
    FROM  CRYPTO.CRYPTO_BITCOIN."OUTPUTS",
          LATERAL FLATTEN(input => "addresses") el
    WHERE "block_timestamp" >= 1506816000000000
      AND "block_timestamp" <  1509494400000000
), address_stats AS (
    /* 2.  For every address, keep its last transaction-date in October
          and the total value of all its October transactions             */
    SELECT
        "ADDRESS",
        MAX("TXN_DATE")                       AS "LAST_TXN_DATE",
        SUM("AMOUNT")                         AS "TOTAL_OCT_VALUE"
    FROM monthly_txns
    GROUP BY "ADDRESS"
), latest_date AS (
    /* 3.  Find the very latest date reached by any address in October */
    SELECT MAX("LAST_TXN_DATE") AS "GLOBAL_LAST_DATE"
    FROM   address_stats
), finalists AS (
    /* 4.  Keep only addresses whose last date equals the global latest */
    SELECT   a.*
    FROM     address_stats a
    JOIN     latest_date d
          ON a."LAST_TXN_DATE" = d."GLOBAL_LAST_DATE"
)
/* 5.  Pick the address with the highest cumulative value (ties settled by value) */
SELECT  "ADDRESS",
        "LAST_TXN_DATE",
        "TOTAL_OCT_VALUE"
FROM    finalists
ORDER BY "TOTAL_OCT_VALUE" DESC NULLS LAST
LIMIT 1;