SELECT "address", ROUND(SUM("balance_change") / 1e18, 4) AS "balance"
FROM (
    SELECT "to_address" AS "address", CAST("value" AS NUMBER) AS "balance_change"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
    UNION ALL
    SELECT "from_address" AS "address", -CAST("value" AS NUMBER) AS "balance_change"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
) AS "transfers"
GROUP BY "address"
HAVING SUM("balance_change") > 0
ORDER BY "balance" ASC
LIMIT 3;