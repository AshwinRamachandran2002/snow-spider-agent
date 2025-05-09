WITH OutputsPerAddress AS (
    SELECT
        f.value::STRING AS "address",
        t."type",
        SUM(t."value") AS "total_output_value"
    FROM
        "CRYPTO"."CRYPTO_BITCOIN_CASH"."OUTPUTS" t,
        LATERAL FLATTEN(input => t."addresses") f
    WHERE
        t."block_timestamp" BETWEEN 1393632000000000 AND 1396223999000000
    GROUP BY
        "address",
        t."type"
),
InputsPerAddress AS (
    SELECT
        f.value::STRING AS "address",
        t."type",
        SUM(t."value") AS "total_input_value"
    FROM
        "CRYPTO"."CRYPTO_BITCOIN_CASH"."INPUTS" t,
        LATERAL FLATTEN(input => t."addresses") f
    WHERE
        t."block_timestamp" BETWEEN 1393632000000000 AND 1396223999000000
    GROUP BY
        "address",
        t."type"
),
BalancesPerAddress AS (
    SELECT
        COALESCE(o."address", i."address") AS "address",
        COALESCE(o."type", i."type") AS "type",
        COALESCE(o."total_output_value", 0) AS "total_output_value",
        COALESCE(i."total_input_value", 0) AS "total_input_value",
        COALESCE(o."total_output_value", 0) - COALESCE(i."total_input_value", 0) AS "balance"
    FROM
        OutputsPerAddress o
        FULL OUTER JOIN InputsPerAddress i
            ON o."address" = i."address" AND o."type" = i."type"
)
SELECT
    "type",
    ROUND(MAX("balance"), 4) AS "max_balance",
    ROUND(MIN("balance"), 4) AS "min_balance"
FROM
    BalancesPerAddress
GROUP BY
    "type";