WITH outputs_avg AS (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp")) AS "Year",
        AVG("value") AS "Average_Output_Value_FROM_OUTPUTS"
    FROM "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS"
    GROUP BY "Year"
),
transactions_avg AS (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp")) AS "Year",
        AVG("output_value") AS "Average_Output_Value_FROM_TRANSACTIONS"
    FROM "CRYPTO"."CRYPTO_BITCOIN"."TRANSACTIONS"
    GROUP BY "Year"
)
SELECT
    o."Year",
    ROUND(ABS(o."Average_Output_Value_FROM_OUTPUTS" - t."Average_Output_Value_FROM_TRANSACTIONS"), 4) AS "Difference_in_Average_Output_Value"
FROM outputs_avg o
JOIN transactions_avg t ON o."Year" = t."Year"
ORDER BY o."Year"