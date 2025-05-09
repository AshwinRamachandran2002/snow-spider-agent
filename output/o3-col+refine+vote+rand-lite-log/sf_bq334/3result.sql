WITH merged AS (
    /* combine inputs & outputs, keeping a flag that tells the origin */
    SELECT 'OUTPUT' AS "src",
           "block_timestamp",
           "value"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    UNION ALL
    SELECT 'INPUT'  AS "src",
           "block_timestamp",
           "value"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"
),
/* yearly avg computed on the merged set but restricted to OUTPUT rows */
merged_yearly AS (
    SELECT
        TO_CHAR(
            TO_TIMESTAMP_NTZ("block_timestamp" / 1000000),
            'YYYY'
        )                              AS "year",
        AVG("value")                   AS "avg_output_value_merged"
    FROM   merged
    WHERE  "src" = 'OUTPUT'
    GROUP  BY 1
),
/* yearly avg straight from the transactions table */
tx_yearly AS (
    SELECT
        TO_CHAR(
            TO_TIMESTAMP_NTZ("block_timestamp" / 1000000),
            'YYYY'
        )                              AS "year",
        AVG("output_value")            AS "avg_output_value_tx"
    FROM   CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    GROUP  BY 1
)
/* show the difference (merged – tx) only for the years present in both sets */
SELECT
    m."year",
    m."avg_output_value_merged" - t."avg_output_value_tx" AS "difference"
FROM   merged_yearly m
JOIN   tx_yearly     t
       ON m."year" = t."year"
ORDER  BY m."year";