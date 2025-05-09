WITH bnb_token AS (
    /* BNB ERC‑20 contract(s) and their decimals */
    SELECT DISTINCT
           "address"      AS token_address,
           COALESCE(TRY_TO_NUMBER("decimals"), 18) AS decimals
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKENS
    WHERE UPPER("symbol") = 'BNB'
),
bnb_transfers AS (
    /* All BNB transfers, skipping the zero address on both sides */
    SELECT
        tt."from_address",
        tt."to_address",
        TRY_TO_NUMBER(tt."value")          AS raw_value,   -- value in the token’s smallest unit
        bt.decimals
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tt
    JOIN bnb_token bt
      ON tt."token_address" = bt.token_address
    WHERE  LOWER(tt."from_address") <> '0x0000000000000000000000000000000000000000'
      AND  LOWER(tt."to_address")   <> '0x0000000000000000000000000000000000000000'
),
address_flows AS (
    /* Received and sent per address */
    SELECT "to_address"   AS address, SUM(raw_value) AS received, 0                AS sent, MAX(decimals) AS decimals
    FROM   bnb_transfers
    GROUP  BY "to_address"
    
    UNION ALL
    
    SELECT "from_address" AS address, 0              AS received, SUM(raw_value)   AS sent, MAX(decimals) AS decimals
    FROM   bnb_transfers
    GROUP  BY "from_address"
),
balances AS (
    /* Net balance per address, keep only non‑zero balances */
    SELECT
        address,
        SUM(received) - SUM(sent) AS balance_raw,   -- still in smallest unit
        MAX(decimals)             AS decimals
    FROM address_flows
    GROUP BY address
    HAVING SUM(received) - SUM(sent) <> 0
)

SELECT
    SUM(balance_raw) / POWER(10, 18)  AS circulating_supply_bnb   -- convert from wei‑like unit to token units
FROM balances;