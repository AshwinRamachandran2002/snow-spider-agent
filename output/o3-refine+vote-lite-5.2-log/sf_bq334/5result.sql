WITH "COMBINED" AS (
    /* Merge INPUTS and OUTPUTS, tagging record type                       */
    SELECT
        'output'                                      AS "REC_TYPE",
        YEAR(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "YEAR",
        TO_DOUBLE("value")                            AS "VALUE"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"

    UNION ALL

    SELECT
        'input'                                       AS "REC_TYPE",
        YEAR(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "YEAR",
        TO_DOUBLE("value")                            AS "VALUE"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"
),

/* Yearly average using OUTPUT records from the merged set                 */
"OUTPUTS_YEARLY" AS (
    SELECT
        "YEAR",
        AVG("VALUE") AS "AVG_OUTPUT_VALUE"
    FROM "COMBINED"
    WHERE "REC_TYPE" = 'output'
    GROUP BY "YEAR"
),

/* Yearly average directly from TRANSACTIONS table                         */
"TX_YEARLY" AS (
    SELECT
        YEAR(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "YEAR",
        AVG(TO_DOUBLE("output_value"))                  AS "AVG_TX_OUTPUT_VALUE"
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    WHERE "output_value" IS NOT NULL
    GROUP BY "YEAR"
),

/* Compute differences for years present in both methods                   */
"DIFFS" AS (
    SELECT
        o."YEAR",
        o."AVG_OUTPUT_VALUE" - t."AVG_TX_OUTPUT_VALUE" AS "DIFFERENCE"
    FROM "OUTPUTS_YEARLY" o
    JOIN "TX_YEARLY"     t USING ("YEAR")
)

SELECT
    "YEAR",
    "DIFFERENCE"
FROM "DIFFS"
ORDER BY "YEAR";