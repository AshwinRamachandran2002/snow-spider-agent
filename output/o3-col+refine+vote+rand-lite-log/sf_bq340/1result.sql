WITH token_transfers AS (          -- (+) incoming | (–) outgoing
    SELECT  "block_number",
            "to_address"                       AS "addr",
            TRY_TO_NUMBER("value")            AS "delta"
    FROM    CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE   "token_address" IN (
                '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
                '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
            )

    UNION ALL

    SELECT  "block_number",
            "from_address"                     AS "addr",
            -TRY_TO_NUMBER("value")           AS "delta"
    FROM    CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE   "token_address" IN (
                '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
                '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
            )
),
running_balances AS (               -- cumulative balance per address
    SELECT  "addr",
            "block_number",
            SUM("delta") OVER (
                PARTITION BY "addr"
                ORDER BY      "block_number"
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )                                         AS "balance"
    FROM    token_transfers
),
step_changes AS (                   -- |Δ balance| between successive txs
    SELECT  "addr",
            ABS(
                "balance" -
                LAG("balance") OVER (
                    PARTITION BY "addr"
                    ORDER BY      "block_number"
                )
            )                                       AS "jump"
    FROM    running_balances
),
max_jump_per_addr AS (              -- largest change per address
    SELECT  "addr",
            MAX("jump") AS "largest_jump"
    FROM    step_changes
    WHERE   "jump" IS NOT NULL
    GROUP BY "addr"
)
SELECT  "addr" AS "ethereum_address",
        "largest_jump"
FROM    max_jump_per_addr
WHERE   "addr" <> '0x0000000000000000000000000000000000000000'
ORDER BY "largest_jump" DESC NULLS LAST
LIMIT 6;