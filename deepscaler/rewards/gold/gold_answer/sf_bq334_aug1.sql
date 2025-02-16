-- Task: Calculate the yearly average value of outputs from the merged inputs and outputs tables (filtered to outputs).

WITH all_transactions AS (
    SELECT 
        TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS "timestamp",  -- Convert timestamp to datetime
        "value",
        'input' AS "type"
    FROM 
        "CRYPTO"."CRYPTO_BITCOIN"."INPUTS"
    UNION ALL
    SELECT 
        TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS "timestamp",  -- Convert timestamp to datetime
        "value",
        'output' AS "type"
    FROM 
        "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS"
)

SELECT
    EXTRACT(YEAR FROM "timestamp") AS "year",
    AVG("value") AS "avg_value"
FROM 
    all_transactions
WHERE "type" = 'output'
GROUP BY "year"
ORDER BY "year";