WITH bnb_movements AS (
    /* outgoing transfers (subtract) */
    SELECT
        LOWER("from_address")                    AS address,
        -TRY_TO_DECIMAL("value")                 AS delta
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
      AND "from_address" IS NOT NULL
      AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'

    UNION ALL

    /* incoming transfers (add) */
    SELECT
        LOWER("to_address")                      AS address,
        TRY_TO_DECIMAL("value")                  AS delta
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
      AND "to_address" IS NOT NULL
      AND LOWER("to_address") <> '0x0000000000000000000000000000000000000000'
),
address_balances AS (
    SELECT
        address,
        SUM(delta)                               AS balance
    FROM bnb_movements
    GROUP BY address
    HAVING SUM(delta) <> 0                        -- keep only non‑zero balances
)
SELECT
    SUM(balance) / 1000000000000000000           AS "circulating_supply_BNB"
FROM address_balances;