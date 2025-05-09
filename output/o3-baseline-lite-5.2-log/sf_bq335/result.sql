WITH combined AS (
    /* Inputs table */
    SELECT
        f.value::TEXT                                                   AS "address",
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))              AS "tx_date",
        "value"::NUMBER                                                 AS "tx_value"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
         ,LATERAL FLATTEN(input => "addresses") f
    WHERE "block_timestamp" BETWEEN 1506816000000000               -- 2017‑10‑01 00:00:00 UTC
                               AND     1509494399999999            -- 2017‑10‑31 23:59:59 UTC

    UNION ALL

    /* Outputs table */
    SELECT
        f.value::TEXT                                                   AS "address",
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1000000))              AS "tx_date",
        "value"::NUMBER                                                 AS "tx_value"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
         ,LATERAL FLATTEN(input => "addresses") f
    WHERE "block_timestamp" BETWEEN 1506816000000000
                               AND     1509494399999999
),

addr_stats AS (
    SELECT
        "address",
        MAX("tx_date")                              AS "latest_date",
        SUM("tx_value")                             AS "total_value"
    FROM combined
    GROUP BY "address"
),

max_date AS (
    SELECT MAX("latest_date") AS "latest_overall_date"
    FROM   addr_stats
),

filtered AS (
    SELECT s.*
    FROM   addr_stats s
           JOIN max_date m
             ON s."latest_date" = m."latest_overall_date"
)

SELECT
    "address",
    "latest_date",
    "total_value"
FROM   filtered
ORDER BY
    "total_value" DESC NULLS LAST,
    "address"
LIMIT 1;