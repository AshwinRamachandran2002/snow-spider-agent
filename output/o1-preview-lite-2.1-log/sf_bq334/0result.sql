SELECT o."Year",
       ROUND(ABS(o."Average_Output_Value" - t."Average_Output_Value"), 4) AS "Difference_in_Average_Output_Value"
FROM (
    SELECT EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "Year",
           AVG("value") AS "Average_Output_Value"
    FROM "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS"
    GROUP BY "Year"
) AS o
JOIN (
    SELECT EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "Year",
           AVG("output_value") AS "Average_Output_Value"
    FROM "CRYPTO"."CRYPTO_BITCOIN"."TRANSACTIONS"
    GROUP BY "Year"
) AS t
ON o."Year" = t."Year"
ORDER BY o."Year";