WITH in_transfers AS (
    SELECT
        "to_address"                     AS "address",
        SUM(TO_NUMBER("value"))          AS "in_amt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "to_address"
),
out_transfers AS (
    SELECT
        "from_address"                   AS "address",
        SUM(TO_NUMBER("value"))          AS "out_amt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    GROUP BY "from_address"
)
SELECT
    COALESCE(in_transfers."address", out_transfers."address")                                   AS "ethereum_address",
    COALESCE(in_transfers."in_amt", 0) - COALESCE(out_transfers."out_amt", 0)                   AS "net_balance"
FROM in_transfers
FULL OUTER JOIN out_transfers USING ("address")
WHERE (COALESCE(in_transfers."in_amt", 0) - COALESCE(out_transfers."out_amt", 0)) > 0
ORDER BY "net_balance" ASC
LIMIT 3;