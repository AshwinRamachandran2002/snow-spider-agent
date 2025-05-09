WITH bnb_token AS (   -- ERC-20 contract address of BNB on Ethereum
    SELECT LOWER("address") AS token_address
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKENS
    WHERE UPPER("symbol") = 'BNB'
    ORDER BY "block_number" ASC NULLS LAST
    LIMIT 1
),

bnb_transfers AS (    -- all BNB transfers
    SELECT
        LOWER("from_address") AS from_addr,
        LOWER("to_address")   AS to_addr,
        TO_NUMBER("value")    AS value_wei          -- amount in Wei
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
    JOIN bnb_token bt
      ON LOWER(tt."token_address") = bt.token_address
    WHERE "value" IS NOT NULL
),

address_flows AS (    -- +value for receives, –value for sends (zero-address excluded)
    SELECT  to_addr  AS addr,
            value_wei AS delta
    FROM bnb_transfers
    WHERE to_addr  <> '0x0000000000000000000000000000000000000000'

    UNION ALL

    SELECT  from_addr AS addr,
            -value_wei AS delta
    FROM bnb_transfers
    WHERE from_addr <> '0x0000000000000000000000000000000000000000'
),

balances AS (         -- net balance per non-zero address
    SELECT addr,
           SUM(delta) AS balance_wei
    FROM address_flows
    GROUP BY addr
)

SELECT
    SUM(balance_wei) / 1000000000000000000 AS circulating_supply    -- convert Wei → tokens (10¹⁸)
FROM balances
WHERE addr <> '0x0000000000000000000000000000000000000000'
  AND balance_wei <> 0;