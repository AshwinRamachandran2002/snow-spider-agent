WITH bnb_token AS (
    SELECT LOWER("address") AS token_address
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKENS"
    WHERE "symbol" = 'BNB'
),
filtered_transfers AS (
    SELECT
        LOWER(tt."from_address") AS from_addr,
        LOWER(tt."to_address")   AS to_addr,
        TRY_TO_DECIMAL(tt."value") AS value_raw
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
    JOIN bnb_token bt
      ON LOWER(tt."token_address") = bt.token_address
    WHERE tt."from_address" IS NOT NULL
      AND tt."to_address"   IS NOT NULL
      AND LOWER(tt."from_address") <> '0x0000000000000000000000000000000000000000'
      AND LOWER(tt."to_address")   <> '0x0000000000000000000000000000000000000000'
),
address_flows AS (
    /* inflows */
    SELECT to_addr AS addr, SUM(value_raw) AS received, 0 AS sent
    FROM filtered_transfers
    GROUP BY to_addr
    UNION ALL
    /* outflows */
    SELECT from_addr AS addr, 0 AS received, SUM(value_raw) AS sent
    FROM filtered_transfers
    GROUP BY from_addr
),
address_balances AS (
    SELECT
        addr,
        SUM(received) - SUM(sent) AS balance_raw
    FROM address_flows
    GROUP BY addr
    HAVING SUM(received) - SUM(sent) <> 0      -- keep only non-zero balances
)
SELECT
    SUM(balance_raw) / POWER(10,18) AS "BNB_CIRCULATING_SUPPLY"
FROM address_balances;