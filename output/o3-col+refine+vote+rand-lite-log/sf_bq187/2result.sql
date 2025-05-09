/*  Circulating supply of the main “BNB” ERC-20 contract  
    – balances are summed over all non-zero addresses and
      converted from raw Wei to 18-decimal BNB units          */

WITH active_token AS (           -- pick the most-active BNB contract
    SELECT tt."token_address"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS  tt
    JOIN   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKENS           t
           ON  t."address" = tt."token_address"
    WHERE  t."symbol" ILIKE 'BNB'
    GROUP  BY tt."token_address"
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT  1
),

received AS (                    -- total BNB an address has received
    SELECT  tt."to_address"                      AS "addr",
            SUM(TRY_TO_NUMBER(tt."value"))       AS "received_raw"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tt
    JOIN    active_token at
            ON  at."token_address" = tt."token_address"
    WHERE   tt."to_address" NOT ILIKE '0x000%'          -- exclude zero-addr
    GROUP   BY tt."to_address"
),

sent AS (                        -- total BNB an address has sent
    SELECT  tt."from_address"                    AS "addr",
            SUM(TRY_TO_NUMBER(tt."value"))       AS "sent_raw"
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tt
    JOIN    active_token at
            ON  at."token_address" = tt."token_address"
    WHERE   tt."from_address" NOT ILIKE '0x000%'        -- exclude zero-addr
    GROUP   BY tt."from_address"
),

balances AS (                    -- net balance per address
    SELECT  COALESCE(r."addr", s."addr")                         AS "address",
            COALESCE(r."received_raw", 0)
          - COALESCE(s."sent_raw",     0)                        AS "balance_raw"
    FROM    received r
    FULL OUTER JOIN sent s
      ON    r."addr" = s."addr"
)

SELECT
    SUM("balance_raw") / POWER(10, 18)  AS "circulating_supply_BNB"
FROM balances
WHERE "balance_raw" <> 0;