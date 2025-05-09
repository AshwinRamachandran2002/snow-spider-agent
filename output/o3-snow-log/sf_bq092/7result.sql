WITH tx_april AS (
    SELECT
        "hash" AS txhash
    FROM CRYPTO.CRYPTO_DASH.TRANSACTIONS
    WHERE "block_timestamp_month" = '2023-04-01'
),
outputs_april AS (
    SELECT
        ARRAY_TO_STRING("addresses", ',')        AS "address",
        "type",
        CAST("value" AS NUMBER)                  AS "amount"
    FROM CRYPTO.CRYPTO_DASH.OUTPUTS
    WHERE "transaction_hash" IN (SELECT txhash FROM tx_april)
),
inputs_april AS (
    SELECT
        ARRAY_TO_STRING("addresses", ',')        AS "address",
        "type",
        -CAST("value" AS NUMBER)                 AS "amount"   -- debit (negative)
    FROM CRYPTO.CRYPTO_DASH.INPUTS
    WHERE "transaction_hash" IN (SELECT txhash FROM tx_april)
),
all_entries AS (            -- combine debits and credits
    SELECT * FROM outputs_april
    UNION ALL
    SELECT * FROM inputs_april
),
balances AS (               -- net balance per address + type
    SELECT
        "address",
        "type",
        SUM("amount") AS balance
    FROM all_entries
    GROUP BY "address", "type"
),
extremes AS (               -- highest and lowest balances
    SELECT * FROM (
        (SELECT "address", "type", balance
         FROM balances
         ORDER BY balance DESC NULLS LAST
         LIMIT 1)
        UNION ALL
        (SELECT "address", "type", balance
         FROM balances
         ORDER BY balance ASC NULLS LAST
         LIMIT 1)
    )
)
SELECT
    "address",
    "type",
    balance
FROM extremes;