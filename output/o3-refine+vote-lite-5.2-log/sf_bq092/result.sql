WITH io_union AS (

    /* Dash INPUTS  (debits = negative values) */
    SELECT
        ARRAY_TO_STRING("addresses", ',')                                  AS "address",
        "type"                                                             AS "type",
        -1 * TO_NUMBER("value")                                            AS "amount",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) AS "month"
    FROM CRYPTO.CRYPTO_DASH.INPUTS

    UNION ALL

    /* Dash OUTPUTS  (credits = positive values) */
    SELECT
        ARRAY_TO_STRING("addresses", ',')                                  AS "address",
        "type"                                                             AS "type",
        TO_NUMBER("value")                                                 AS "amount",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) AS "month"
    FROM CRYPTO.CRYPTO_DASH.OUTPUTS
),

balances AS (
    /* keep only April‑2023 transactions and calculate net balance per (address,type) */
    SELECT
        "address",
        "type",
        SUM("amount") AS "balance"
    FROM io_union
    WHERE "month" = '2023-04-01'
    GROUP BY
        "address",
        "type"
),

extremes AS (
    /* determine the highest and lowest balances */
    SELECT
        MAX("balance") AS "max_balance",
        MIN("balance") AS "min_balance"
    FROM balances
)

SELECT
    b."address",
    b."type",
    b."balance"
FROM balances               b
JOIN extremes               e
  ON b."balance" = e."max_balance"
  OR b."balance" = e."min_balance"
ORDER BY
    b."balance" DESC NULLS LAST;