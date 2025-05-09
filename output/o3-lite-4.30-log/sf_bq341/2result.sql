WITH transfers AS (
    SELECT
        LOWER("from_address") AS "from_addr",
        LOWER("to_address")   AS "to_addr",
        TRY_TO_DECIMAL("value") AS "amt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
      AND TRY_TO_DECIMAL("value") IS NOT NULL
), sent AS (
    SELECT "from_addr" AS "address",
           SUM("amt")  AS "sent_amt"
    FROM transfers
    GROUP BY "from_addr"
), received AS (
    SELECT "to_addr" AS "address",
           SUM("amt") AS "recv_amt"
    FROM transfers
    GROUP BY "to_addr"
), balances AS (
    SELECT
        COALESCE(received."address", sent."address")                    AS "ethereum_address",
        COALESCE(received."recv_amt", 0) - COALESCE(sent."sent_amt", 0) AS "token_balance"
    FROM received
    FULL JOIN sent
        ON received."address" = sent."address"
)
SELECT
    "ethereum_address",
    "token_balance"
FROM balances
WHERE "token_balance" > 0
ORDER BY "token_balance" ASC, "ethereum_address" ASC
LIMIT 3;