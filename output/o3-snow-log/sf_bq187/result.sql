WITH bnb_transfers AS (
    SELECT
        LOWER("from_address") AS from_addr,
        LOWER("to_address")   AS to_addr,
        CAST("value" AS NUMBER(38,0)) AS val
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
      AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
      AND LOWER("to_address")   <> '0x0000000000000000000000000000000000000000'
),
received AS (
    SELECT to_addr AS addr, SUM(val) AS received
    FROM bnb_transfers
    GROUP BY to_addr
),
sent AS (
    SELECT from_addr AS addr, SUM(val) AS sent
    FROM bnb_transfers
    GROUP BY from_addr
),
balances AS (
    SELECT
        COALESCE(r.addr, s.addr)                            AS addr,
        COALESCE(r.received, 0) - COALESCE(s.sent, 0)       AS balance
    FROM received r
    FULL OUTER JOIN sent s
      ON r.addr = s.addr
)
SELECT
    SUM(balance) / POWER(10, 18) AS "BNB_CIRCULATING_SUPPLY"
FROM balances
WHERE balance <> 0;