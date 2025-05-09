WITH bnb_token AS (
    -- contracts whose symbol is exactly 'BNB'
    SELECT LOWER("address") AS token_address
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKENS
    WHERE UPPER("symbol") = 'BNB'
),
bnb_transfers AS (
    -- every transfer that involves a BNB token contract
    SELECT TT.*
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS TT
    JOIN bnb_token BT
      ON LOWER(TT."token_address") = BT.token_address
),
address_flows AS (
    -- positive for receives, negative for sends, skip zero-address
    SELECT LOWER("to_address") AS address,
           TRY_CAST("value" AS NUMBER) AS amount
    FROM bnb_transfers
    WHERE "to_address" IS NOT NULL
      AND LOWER("to_address") <> '0x0000000000000000000000000000000000000000'
    
    UNION ALL
    
    SELECT LOWER("from_address") AS address,
           -TRY_CAST("value" AS NUMBER) AS amount
    FROM bnb_transfers
    WHERE "from_address" IS NOT NULL
      AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
),
net_balances AS (
    -- net balance per address
    SELECT address,
           SUM(amount) AS balance
    FROM address_flows
    GROUP BY address
    HAVING SUM(amount) <> 0
)
SELECT SUM(balance) / 1e18 AS circulating_supply_bnb
FROM net_balances;