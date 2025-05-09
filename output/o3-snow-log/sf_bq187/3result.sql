WITH zero_addr AS (
    SELECT '0x0000000000000000000000000000000000000000' AS z
),

bnb_token AS (       /* BNB ERC-20 contract address on Ethereum */
    SELECT LOWER("address") AS token_address
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKENS
    WHERE LOWER("symbol") = 'bnb'
    ORDER BY "block_number" ASC
    LIMIT 1
),

bnb_transfers AS (   /* all BNB transfer events */
    SELECT
        LOWER(tt."from_address")                  AS from_addr,
        LOWER(tt."to_address")                    AS to_addr,
        TRY_CAST(tt."value" AS NUMBER(38,0))      AS value_wei     -- raw token amount
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS  tt
    JOIN bnb_token bt
          ON LOWER(tt."token_address") = bt.token_address
    WHERE tt."value" IS NOT NULL
),

balance_deltas AS (  /* +value for receiver, ‑value for sender */
    SELECT from_addr AS addr, -value_wei AS delta
    FROM   bnb_transfers
    UNION ALL
    SELECT to_addr   AS addr,  value_wei AS delta
    FROM   bnb_transfers
),

address_balances AS (
    SELECT addr,
           SUM(delta) AS balance_wei
    FROM   balance_deltas, zero_addr
    WHERE  addr <> zero_addr.z                    -- drop the zero address itself
    GROUP  BY addr
)

SELECT
    SUM(balance_wei) / 1e18      AS "CIRCULATING_SUPPLY_BNB"       -- supply in 10^18 units
FROM   address_balances
WHERE  balance_wei > 0;                                            -- sum only positive balances