SELECT
    "address",
    ROUND("balance", 4) AS "balance"
FROM (
    SELECT
        "address",
        SUM("received") - SUM("sent") AS "balance"
    FROM (
        SELECT
            "to_address" AS "address",
            TO_NUMBER("value") / 1e18 AS "received",
            0 AS "sent"
        FROM
            "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
        WHERE
            "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'

        UNION ALL

        SELECT
            "from_address" AS "address",
            0 AS "received",
            TO_NUMBER("value") / 1e18 AS "sent"
        FROM
            "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
        WHERE
            "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    ) AS transfers
    GROUP BY
        "address"
) AS balances
WHERE
    "balance" > 0
ORDER BY
    "balance" ASC NULLS LAST
LIMIT 3;