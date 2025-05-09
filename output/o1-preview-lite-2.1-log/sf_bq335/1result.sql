SELECT
  "address",
  ROUND(SUM("total_value"), 4) AS "Total_Transaction_Value"
FROM (
  SELECT
    f.value::STRING AS "address",
    t."value"::NUMBER AS "total_value",
    TO_TIMESTAMP_NTZ(t."block_timestamp" / 1e6) AS "most_recent_tx_timestamp"
  FROM "CRYPTO"."CRYPTO_BITCOIN"."INPUTS" t,
    LATERAL FLATTEN(input => t."addresses") f
  
  UNION ALL
  
  SELECT
    f.value::STRING AS "address",
    t."value"::NUMBER AS "total_value",
    TO_TIMESTAMP_NTZ(t."block_timestamp" / 1e6) AS "most_recent_tx_timestamp"
  FROM "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS" t,
    LATERAL FLATTEN(input => t."addresses") f
) combined_transactions
GROUP BY "address"
HAVING MAX("most_recent_tx_timestamp") BETWEEN '2017-10-01' AND '2017-10-31 23:59:59'
ORDER BY "Total_Transaction_Value" DESC NULLS LAST
LIMIT 1;