/* circulating supply of canonical ERC‑20 BNB (0xB8c77482e45F1F44dE1745F52C74426C631bdd52) */

WITH bnb_token AS (
    SELECT '0xb8c77482e45f1f44de1745f52c74426c631bdd52' AS token_address
),

received AS (
    SELECT  "to_address"                      AS addr,
            SUM(TRY_TO_NUMBER("value"))       AS recv_raw
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
    JOIN    bnb_token bt
        ON  tt."token_address" = bt.token_address
    WHERE   "to_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "to_address"
),

sent AS (
    SELECT  "from_address"                    AS addr,
            SUM(TRY_TO_NUMBER("value"))       AS sent_raw
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN."TOKEN_TRANSFERS" tt
    JOIN    bnb_token bt
        ON  tt."token_address" = bt.token_address
    WHERE   "from_address" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "from_address"
),

balances AS (
    SELECT  COALESCE(r.addr, s.addr)                          AS holder,
            COALESCE(r.recv_raw, 0) - COALESCE(s.sent_raw, 0) AS balance_raw
    FROM    received r
    FULL OUTER JOIN sent s ON r.addr = s.addr
)

SELECT
    'BNB'                                                   AS token,
    ROUND(SUM(balance_raw) / POWER(10, 18), 4)              AS circulating_supply
FROM balances
WHERE balance_raw > 0;