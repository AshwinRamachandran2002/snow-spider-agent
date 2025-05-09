WITH transfers AS (      -- +value to receiver, -value from sender
    SELECT
        LOWER("token_address")             AS token_address,
        LOWER("to_address")                AS ethereum_address,
        "block_number",
        TRY_TO_NUMBER("value")             AS delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',   -- BAT
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'    -- QKC
          )
      AND "to_address" <> '0x0000000000000000000000000000000000000000'

    UNION ALL

    SELECT
        LOWER("token_address")             AS token_address,
        LOWER("from_address")              AS ethereum_address,
        "block_number",
        -TRY_TO_NUMBER("value")            AS delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
          )
      AND "from_address" <> '0x0000000000000000000000000000000000000000'
),

balances AS (         -- running balance per token & address
    SELECT
        token_address,
        ethereum_address,
        "block_number",
        SUM(delta) OVER (
            PARTITION BY token_address, ethereum_address
            ORDER BY "block_number"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS balance,
        ROW_NUMBER() OVER (
            PARTITION BY token_address, ethereum_address
            ORDER BY "block_number" DESC
        ) AS rn
    FROM transfers
),

latest_two AS (       -- newest and previous balance snapshots
    SELECT
        token_address,
        ethereum_address,
        MAX(CASE WHEN rn = 1 THEN balance END) AS current_balance,
        MAX(CASE WHEN rn = 2 THEN balance END) AS previous_balance
    FROM balances
    WHERE rn <= 2
    GROUP BY token_address, ethereum_address
)

SELECT
    ethereum_address,
    SUM(ABS(current_balance - previous_balance)) AS absolute_balance_difference
FROM latest_two
WHERE previous_balance IS NOT NULL
GROUP BY ethereum_address
ORDER BY absolute_balance_difference DESC NULLS LAST, ethereum_address
LIMIT 6;