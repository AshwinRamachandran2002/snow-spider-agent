WITH all_tx AS (
    /* --------------- Inputs --------------- */
    SELECT
        f.value::string                                             AS "address",
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))      AS "tx_date",
        "value"                                                     AS "tx_value"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS,
         LATERAL FLATTEN(input => "addresses") f
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))
          BETWEEN '2017-10-01' AND '2017-10-31'

    UNION ALL

    /* --------------- Outputs -------------- */
    SELECT
        f.value::string                                             AS "address",
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))      AS "tx_date",
        "value"                                                     AS "tx_value"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS,
         LATERAL FLATTEN(input => "addresses") f
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000))
          BETWEEN '2017-10-01' AND '2017-10-31'
),

/* Per–address statistics for October-2017 */
addr_stats AS (
    SELECT
        "address",
        MAX("tx_date")                      AS "last_tx_date",
        SUM("tx_value")                     AS "total_tx_value"
    FROM all_tx
    GROUP BY "address"
),

/* Identify the latest day in October-2017 on which any address transacted */
latest_day AS (
    SELECT MAX("last_tx_date") AS "global_latest_date"
    FROM   addr_stats
),

/* Keep only addresses whose final transaction happened on that latest day */
finalists AS (
    SELECT a.*
    FROM   addr_stats a
    JOIN   latest_day d
           ON a."last_tx_date" = d."global_latest_date"
)

/* Pick the address with the largest total value among those finalists */
SELECT
    "address",
    "last_tx_date",
    "total_tx_value"
FROM   finalists
ORDER  BY "total_tx_value" DESC NULLS LAST
LIMIT  1;