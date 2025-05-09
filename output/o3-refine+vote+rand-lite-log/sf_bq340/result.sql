WITH token_transfers AS (
    SELECT
        LOWER("from_address")        AS address,
        -TO_DECIMAL("value")         AS delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") IN (
        '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
        '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
    )

    UNION ALL

    SELECT
        LOWER("to_address")          AS address,
        TO_DECIMAL("value")          AS delta
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") IN (
        '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
        '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
    )
),

balances AS (
    SELECT
        address,
        SUM(delta)          AS current_balance
    FROM token_transfers
    GROUP BY address
),

differences AS (
    /* previous balance is assumed 0 (no earlier data in scope) */
    SELECT
        address,
        ABS(current_balance) AS absolute_difference
    FROM balances
    WHERE address <> '0x0000000000000000000000000000000000000000'
)

SELECT
    address
FROM differences
ORDER BY
    absolute_difference DESC NULLS LAST,
    address
LIMIT 6;