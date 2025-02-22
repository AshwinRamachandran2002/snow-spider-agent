-- Task: For the token at address "0xa92a861fc11b99b24296af880011b47f9cafb5ab", what is the total value received by each Ethereum address? Limit the result to the first 100 addresses.

WITH transaction_addresses AS (
    SELECT 
        "from_address", 
        "to_address", 
        CAST("value" AS NUMERIC) / 1000000 AS "value"
    FROM 
        "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
    WHERE 
        "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
)

SELECT 
    "to_address",
    SUM("value") AS "total_value_received"
FROM 
    transaction_addresses
GROUP BY 
    "to_address"
LIMIT 100;