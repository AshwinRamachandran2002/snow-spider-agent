WITH transactions AS (
    -- Select debits from Bitcoin inputs within the specified date range
    SELECT
        f.value::STRING AS "address",
        -t."value" AS "amount",
        t."type"
    FROM
        CRYPTO.CRYPTO_BITCOIN.INPUTS t,
        LATERAL FLATTEN(input => t."addresses") f
    WHERE
        t."block_timestamp" >= 1393632000000000  -- 2014-03-01 in microseconds
        AND t."block_timestamp" < 1396310400000000  -- 2014-04-01 in microseconds

    UNION ALL

    -- Select credits from Bitcoin outputs within the specified date range
    SELECT
        f.value::STRING AS "address",
        t."value" AS "amount",
        t."type"
    FROM
        CRYPTO.CRYPTO_BITCOIN.OUTPUTS t,
        LATERAL FLATTEN(input => t."addresses") f
    WHERE
        t."block_timestamp" >= 1393632000000000  -- 2014-03-01 in microseconds
        AND t."block_timestamp" < 1396310400000000  -- 2014-04-01 in microseconds
)

-- Calculate the maximum and minimum final balances grouped by address type
SELECT
    "type",
    ROUND(MAX("final_balance"), 4) AS "max_balance",
    ROUND(MIN("final_balance"), 4) AS "min_balance"
FROM (
    SELECT
        "address",
        "type",
        SUM("amount") AS "final_balance"
    FROM
        transactions
    GROUP BY
        "address",
        "type"
)
GROUP BY
    "type"
ORDER BY
    "type";