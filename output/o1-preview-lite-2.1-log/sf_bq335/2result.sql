SELECT "address" AS "Address", ROUND(SUM("value"), 4) AS "Total_Transaction_Value"
FROM (
  SELECT 
    f.VALUE::STRING AS "address",
    t."block_timestamp",
    t."value"
  FROM "CRYPTO"."CRYPTO_BITCOIN"."INPUTS" t,
       LATERAL FLATTEN(input => t."addresses") f
  UNION ALL
  SELECT 
    f.VALUE::STRING AS "address",
    t."block_timestamp",
    t."value"
  FROM "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS" t,
       LATERAL FLATTEN(input => t."addresses") f
) transactions
GROUP BY "address"
HAVING MAX("block_timestamp") BETWEEN 1506816000000000 AND 1509494399000000
ORDER BY "Total_Transaction_Value" DESC NULLS LAST
LIMIT 1;