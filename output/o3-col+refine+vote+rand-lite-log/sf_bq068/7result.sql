WITH movements AS (
    /* credits (outputs) */
    SELECT
        "addresses",
        "type",
        CAST("value" AS NUMBER)             AS "amount"
    FROM CRYPTO.CRYPTO_BITCOIN_CASH.OUTPUTS
    WHERE "block_timestamp" BETWEEN 1393632000000000 AND 1396310400000000

    UNION ALL

    /* debits (inputs) */
    SELECT
        "addresses",
        "type",
        -CAST("value" AS NUMBER)            AS "amount"
    FROM CRYPTO.CRYPTO_BITCOIN_CASH.INPUTS
    WHERE "block_timestamp" BETWEEN 1393632000000000 AND 1396310400000000
),
balances AS (
    /* net balance per address & address-type */
    SELECT
        "addresses",
        "type",
        SUM("amount")                       AS "final_balance"
    FROM movements
    GROUP BY
        "addresses",
        "type"
)
SELECT
    "type",
    MAX("final_balance")                   AS "maximum_balance",
    MIN("final_balance")                   AS "minimum_balance"
FROM balances
GROUP BY
    "type";