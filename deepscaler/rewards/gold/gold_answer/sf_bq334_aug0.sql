-- Task: Calculate the yearly differences between the average Bitcoin output values obtained through two methods:

-- 1. Merged Input/Output Records Method:
--    - Combine the "INPUTS" and "OUTPUTS" tables from the "CRYPTO"."CRYPTO_BITCOIN" schema.
--    - Convert "block_timestamp" to timestamp format.
--    - Label records as 'input' or 'output'.
--    - Filter to include only 'output' records.
--    - Extract the year from the timestamp.
--    - Calculate the average "value" per year.

-- 2. Transactions Table Method:
--    - Use the "TRANSACTIONS" table from the same schema.
--    - Convert "block_timestamp" to timestamp format.
--    - Extract the year from the timestamp.
--    - Calculate the average "output_value" per year.

-- For years present in both methods, compute the difference between the average output values (Transactions average minus Merged Outputs average). Display the differences along with the corresponding years, ordered by year.

WITH all_transactions AS (
    SELECT 
        TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS "timestamp",  -- Convert microseconds to timestamp
        "value",
        'input' AS "type"
    FROM 
        "CRYPTO"."CRYPTO_BITCOIN"."INPUTS"
    UNION ALL
    SELECT 
        TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS "timestamp",  -- Convert microseconds to timestamp
        "value",
        'output' AS "type"
    FROM 
        "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS"
),
filtered_transactions AS (
    SELECT
        EXTRACT(YEAR FROM "timestamp") AS "year",
        "value"
    FROM 
        all_transactions
    WHERE "type" = 'output'
),
average_output_values AS (
    SELECT
        "year",
        AVG("value") AS "avg_value"
    FROM 
        filtered_transactions
    GROUP BY "year"
),
average_transaction_values AS (
    SELECT 
        EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) AS "year",  -- Convert microseconds to timestamp
        AVG("output_value") AS "avg_transaction_value" 
    FROM 
        "CRYPTO"."CRYPTO_BITCOIN"."TRANSACTIONS" 
    GROUP BY "year" 
    ORDER BY "year"
),
common_years AS (
    SELECT
        ao."year",
        ao."avg_value" AS "avg_output_value",
        atv."avg_transaction_value"
    FROM
        average_output_values ao
    JOIN
        average_transaction_values atv 
            ON ao."year" = atv."year"
)
SELECT
    "year",
    "avg_transaction_value" - "avg_output_value" AS "difference"
FROM
    common_years
ORDER BY
    "year";