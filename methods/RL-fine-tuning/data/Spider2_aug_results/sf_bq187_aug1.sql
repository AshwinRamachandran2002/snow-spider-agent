-- Task: Calculate the total amount of 'BNB' tokens received by each address, excluding transactions where the 'to_address' is the zero address (0x000...).

WITH tokenInfo AS (
    SELECT "address"
    FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKENS"
    WHERE "name" = 'BNB'
)

SELECT "tx"."to_address" AS "addr", 
       SUM(CAST("tx"."value" AS FLOAT) / POWER(10, 18)) AS "amount_received"
FROM "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS" AS "tx"
JOIN tokenInfo ON "tx"."token_address" = tokenInfo."address"
WHERE "tx"."to_address" <> '0x0000000000000000000000000000000000000000'
GROUP BY "tx"."to_address";