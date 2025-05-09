WITH "MERGED_IO" AS (
    SELECT 
        'OUTPUTS' AS "record_type",
        CAST("value" AS FLOAT) AS "value",
        "block_timestamp"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    
    UNION ALL
    
    SELECT 
        'INPUTS' AS "record_type",
        CAST("value" AS FLOAT) AS "value",
        "block_timestamp"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
),

/* yearly average based on merged inputs/outputs, keeping only output records */
"YEARLY_OUTPUTS_AVG" AS (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1e6)) AS "year",
        AVG("value") AS "outputs_avg"
    FROM "MERGED_IO"
    WHERE "record_type" = 'OUTPUTS'
    GROUP BY "year"
),

/* yearly average taken directly from the transactions table */
"YEARLY_TX_AVG" AS (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1e6)) AS "year",
        AVG(CAST("output_value" AS FLOAT)) AS "tx_avg"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    GROUP BY "year"
)

/* compute the difference for years present in both result sets */
SELECT
    o."year",
    ROUND(o."outputs_avg" - t."tx_avg", 4) AS "difference"
FROM "YEARLY_OUTPUTS_AVG" o
JOIN "YEARLY_TX_AVG"     t
  ON o."year" = t."year"
ORDER BY o."year" NULLS LAST;