WITH token_transfers AS (          -- the two requested ERC‑20 contracts
    SELECT
        "token_address",
        "from_address",
        "to_address",
        "value",
        "block_number"
    FROM  "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
    WHERE "token_address" IN ('0x0d8775f648430679a709e98d2b0cb6250d2887ef',
                              '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')
),
signed_rows AS (                   -- positive for credits, negative for debits
    SELECT
        "token_address",
        "to_address"   AS "address",
        "block_number",
        TRY_TO_DECIMAL("value")                AS "amount"
    FROM token_transfers
    WHERE "to_address" <> '0x0000000000000000000000000000000000000000'
    
    UNION ALL
    
    SELECT
        "token_address",
        "from_address" AS "address",
        "block_number",
        -TRY_TO_DECIMAL("value")               AS "amount"
    FROM token_transfers
    WHERE "from_address" <> '0x0000000000000000000000000000000000000000'
),
running_balances AS (              -- cumulative balance per (token,address)
    SELECT
        "token_address",
        "address",
        "block_number",
        SUM("amount") OVER (
              PARTITION BY "token_address","address"
              ORDER BY      "block_number"
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "balance"
    FROM signed_rows
),
last_two AS (                       -- keep only current & previous balances
    SELECT
        "token_address",
        "address",
        "balance",
        ROW_NUMBER() OVER (
              PARTITION BY "token_address","address"
              ORDER BY      "block_number" DESC
        ) AS rn
    FROM running_balances
),
token_diffs AS (                    -- absolute change per token & address
    SELECT
        "token_address",
        "address",
        ABS( MAX(CASE WHEN rn = 1 THEN "balance" END)
          - MAX(CASE WHEN rn = 2 THEN "balance" END) ) AS "abs_change"
    FROM   last_two
    WHERE  rn <= 2
    GROUP BY "token_address","address"
    HAVING COUNT(*) = 2
),
address_changes AS (                -- sum the two token changes
    SELECT
        "address",
        SUM("abs_change") AS "total_abs_change"
    FROM token_diffs
    GROUP BY "address"
)
SELECT
    "address"            AS ethereum_address,
    "total_abs_change"   AS absolute_balance_difference
FROM   address_changes
ORDER  BY "total_abs_change" DESC NULLS LAST, ethereum_address
LIMIT 6;