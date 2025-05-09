WITH transfers AS (
    SELECT
        "block_number",
        "log_index",
        "token_address",
        "from_address",
        "to_address",
        TO_NUMBER("value") AS "value"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" IN (
        '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',   -- BAT (given address)
        '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'     -- second token
    )
),
deltas AS (          -- +value for receiver, ‑value for sender
    SELECT
        "to_address"   AS "address",
        "block_number",
        "log_index",
        "token_address",
        "value"        AS "delta"
    FROM transfers
    UNION ALL
    SELECT
        "from_address" AS "address",
        "block_number",
        "log_index",
        "token_address",
        - "value"      AS "delta"
    FROM transfers
),
balances AS (        -- running balance per address & token
    SELECT
        "address",
        "token_address",
        "block_number",
        "log_index",
        SUM("delta") OVER (
            PARTITION BY "address", "token_address"
            ORDER BY     "block_number", "log_index"
        ) AS "balance"
    FROM deltas
),
diffs AS (           -- absolute difference to previous balance
    SELECT
        "address",
        ABS(
            "balance"
            - LAG("balance") OVER (
                  PARTITION BY "address", "token_address"
                  ORDER BY     "block_number", "log_index"
              )
        ) AS "abs_diff"
    FROM balances
    QUALIFY LAG("balance") OVER (
               PARTITION BY "address", "token_address"
               ORDER BY     "block_number", "log_index"
           ) IS NOT NULL
)
SELECT
    "address",
    MAX("abs_diff") AS "largest_balance_change"
FROM diffs
WHERE "address" <> '0x0000000000000000000000000000000000000000'
GROUP BY "address"
ORDER BY "largest_balance_change" DESC NULLS LAST
LIMIT 6;