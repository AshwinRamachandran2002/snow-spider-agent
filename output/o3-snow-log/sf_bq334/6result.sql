WITH merged_src AS (
    /* bring both tables together and tag their origin */
    SELECT 
        'output'                                     AS "src",
        TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp"/1e6), 'YYYY')   AS "year",
        "value"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    
    UNION ALL
    
    SELECT 
        'input'                                      AS "src",
        TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp"/1e6), 'YYYY')   AS "year",
        "value"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
),

/* keep only output-records from the merged set and compute yearly average */
merged_outputs_yearly AS (
    SELECT
        "year",
        AVG("value") AS "merged_avg"
    FROM merged_src
    WHERE "src" = 'output'
    GROUP BY "year"
),

/* yearly average directly from the transactions table               */
tx_outputs_yearly AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp"/1e6), 'YYYY') AS "year",
        AVG("output_value")                                      AS "tx_avg"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    GROUP BY "year"
)

/* compare years present in both sets and calculate the difference   */
SELECT
    m."year"                     :: INTEGER                     AS "year",
    m."merged_avg",
    t."tx_avg",
    m."merged_avg" - t."tx_avg"  AS "difference"
FROM merged_outputs_yearly  m
JOIN tx_outputs_yearly      t
  ON m."year" = t."year"
ORDER BY "year" NULLS LAST;