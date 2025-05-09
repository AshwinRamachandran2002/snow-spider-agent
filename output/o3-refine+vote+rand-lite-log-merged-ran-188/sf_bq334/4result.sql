WITH merged_io AS (   -- combine inputs & outputs, tag the origin
    SELECT 
        "block_timestamp",
        "value"::NUMBER AS "value",
        'output' AS "src"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    
    UNION ALL
    
    SELECT 
        "block_timestamp",
        "value"::NUMBER AS "value",
        'input'  AS "src"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"
),

yearly_outputs AS (   -- keep only output‑records and get yearly averages
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG("value") AS "avg_output_value"
    FROM merged_io
    WHERE "src" = 'output'
    GROUP BY 1
),

yearly_transactions AS (   -- yearly averages from the transactions table
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG("output_value"::NUMBER) AS "avg_tx_output_value"
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    GROUP BY 1
)

-- difference (only where data exists in BOTH methods)
SELECT
    o."year",
    o."avg_output_value" - t."avg_tx_output_value" AS "difference"
FROM yearly_outputs        o
JOIN yearly_transactions   t
  ON o."year" = t."year"
ORDER BY
    o."year";