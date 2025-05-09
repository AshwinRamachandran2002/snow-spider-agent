SELECT t."Year",
       '+' || ROUND(ABS(t."Avg_Output_Value_Transactions" - o."Avg_Output_Value_Outputs"), 4) AS "Difference_in_Average_Output_Value"
FROM (
  SELECT EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1e6)) AS "Year",
         AVG("output_value") AS "Avg_Output_Value_Transactions"
  FROM "CRYPTO"."CRYPTO_BITCOIN"."TRANSACTIONS"
  GROUP BY "Year"
) t
INNER JOIN (
  SELECT EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1e6)) AS "Year",
         AVG("value") AS "Avg_Output_Value_Outputs"
  FROM "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS"
  GROUP BY "Year"
) o ON t."Year" = o."Year"
ORDER BY t."Year";