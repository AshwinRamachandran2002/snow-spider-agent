WITH union_io AS (
    /* merge INPUTS and OUTPUTS tables and label the source */
    SELECT 
        "block_timestamp",
        "value",
        'OUTPUTS' AS "source"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    
    UNION ALL
    
    SELECT 
        "block_timestamp",
        "value",
        'INPUTS'  AS "source"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"
),

/* keep only rows coming from the OUTPUTS side of the merge */
outputs_only AS (
    SELECT 
        TO_NUMBER(
            TO_CHAR(
                TO_TIMESTAMP("block_timestamp" / 1000000),   -- µs → s → timestamp
            'YYYY')
        )                                       AS "year",
        "value"                                 AS "output_value"
    FROM union_io
    WHERE "source" = 'OUTPUTS'
),

/* yearly average using the merged-records method */
avg_outputs AS (
    SELECT 
        "year",
        AVG("output_value")                     AS "avg_outputs"
    FROM outputs_only
    GROUP BY "year"
),

/* yearly average taken directly from the TRANSACTIONS table */
avg_tx AS (
    SELECT 
        TO_NUMBER(
            TO_CHAR(
                TO_TIMESTAMP("block_timestamp" / 1000000),
            'YYYY')
        )                                       AS "year",
        AVG("output_value")                     AS "avg_tx"
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    GROUP BY "year"
),

/* only keep years present in BOTH result sets */
both_years AS (
    SELECT 
        o."year",
        o."avg_outputs",
        t."avg_tx"
    FROM avg_outputs o
    JOIN avg_tx     t
          ON o."year" = t."year"
)

SELECT
    "year",
    ROUND("avg_outputs" - "avg_tx", 4)          AS "avg_difference"
FROM both_years
ORDER BY "year" NULLS LAST;