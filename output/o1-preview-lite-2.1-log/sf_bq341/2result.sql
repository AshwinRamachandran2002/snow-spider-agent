SELECT received."address" AS "Address", 
       ROUND(("total_received" - COALESCE("total_sent", 0)) / 1e18, 4) AS "Balance"
FROM (
  SELECT "to_address" AS "address", SUM(TRY_TO_NUMBER("value")) AS "total_received"
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
  WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
  GROUP BY "to_address"
) AS received
LEFT JOIN (
  SELECT "from_address" AS "address", SUM(TRY_TO_NUMBER("value")) AS "total_sent"
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
  WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
  GROUP BY "from_address"
) AS sent
ON received."address" = sent."address"
WHERE (("total_received" - COALESCE("total_sent", 0)) / 1e18) > 0
ORDER BY ("total_received" - COALESCE("total_sent", 0)) ASC
LIMIT 3;