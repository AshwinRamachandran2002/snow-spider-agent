WITH merged_io AS (           -- merge INPUTS and OUTPUTS tables
    SELECT 
        "value"::FLOAT  AS "val",
        "block_timestamp"             AS "ts",
        'OUTPUTS'                     AS "src"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"

    UNION ALL

    SELECT 
        "value"::FLOAT  AS "val",
        "block_timestamp"             AS "ts",
        'INPUTS'                      AS "src"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"
),

-- yearly average using only the records that came from OUTPUTS
merged_outputs_yearly AS (
    SELECT
        EXTRACT(year FROM TO_TIMESTAMP("ts"/1e6))       AS "yr",
        AVG("val")                                      AS "avg_val_outputs"
    FROM merged_io
    WHERE "src" = 'OUTPUTS'                             -- keep only OUTPUT records
    GROUP BY "yr"
),

-- yearly average taken directly from the TRANSACTIONS table
tx_yearly AS (
    SELECT
        EXTRACT(year FROM TO_TIMESTAMP("block_timestamp"/1e6))   AS "yr",
        AVG("output_value"::FLOAT)                               AS "avg_val_tx"
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    WHERE "output_value" IS NOT NULL
    GROUP BY "yr"
)

-- final difference for years present in both sets
SELECT
    o."yr",
    o."avg_val_outputs" - t."avg_val_tx"   AS "difference"
FROM merged_outputs_yearly o
JOIN tx_yearly           t  ON o."yr" = t."yr"
ORDER BY o."yr";