WITH all_tx AS (

    /* -------------  Inputs ------------- */
    SELECT
        f.value::string                                             AS "address",
        TO_TIMESTAMP("block_timestamp" / 1000000)                  AS "ts",
        "value"::FLOAT                                             AS "amount"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"  i,
         LATERAL FLATTEN(input => i."addresses") f
    WHERE TO_TIMESTAMP("block_timestamp" / 1000000)
          BETWEEN '2017-10-01' AND '2017-10-31 23:59:59'

    UNION ALL

    /* -------------  Outputs ------------- */
    SELECT
        f.value::string                                             AS "address",
        TO_TIMESTAMP("block_timestamp" / 1000000)                  AS "ts",
        "value"::FLOAT                                             AS "amount"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS" o,
         LATERAL FLATTEN(input => o."addresses") f
    WHERE TO_TIMESTAMP("block_timestamp" / 1000000)
          BETWEEN '2017-10-01' AND '2017-10-31 23:59:59'
),

/* -------------  Aggregate per address ------------- */
per_addr AS (
    SELECT
        "address",
        DATE_TRUNC('day', MAX("ts"))            AS "last_tx_date",
        SUM("amount")                           AS "total_value"
    FROM all_tx
    GROUP BY "address"
),

/* -------------  Find the latest last-transaction date ------------- */
max_date AS (
    SELECT MAX("last_tx_date") AS "latest_date"
    FROM   per_addr
),

/* -------------  Addresses whose last transaction is on that latest date ------------- */
candidates AS (
    SELECT p.*
    FROM   per_addr p
    JOIN   max_date m
      ON   p."last_tx_date" = m."latest_date"
)

/* -------------  Pick the address with the highest total value ------------- */
SELECT  "address"
FROM    candidates
ORDER BY "total_value" DESC NULLS LAST
LIMIT   1;