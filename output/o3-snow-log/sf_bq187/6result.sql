WITH bnb_transfers AS (
    SELECT
        LOWER("from_address")  AS from_addr,
        LOWER("to_address")    AS to_addr,
        TRY_CAST("value" AS NUMBER(38, 0)) AS value_raw
    FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE LOWER("token_address") = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
      AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
      AND LOWER("to_address")   <> '0x0000000000000000000000000000000000000000'
),
received AS (
    SELECT
        to_addr     AS address,
        SUM(value_raw) AS received_raw,
        0              AS sent_raw
    FROM bnb_transfers
    GROUP BY to_addr
),
sent AS (
    SELECT
        from_addr   AS address,
        0              AS received_raw,
        SUM(value_raw) AS sent_raw
    FROM bnb_transfers
    GROUP BY from_addr
),
addr_flows AS (
    SELECT * FROM received
    UNION ALL
    SELECT * FROM sent
),
balances AS (
    SELECT
        address,
        SUM(received_raw) - SUM(sent_raw) AS balance_raw
    FROM addr_flows
    GROUP BY address
    HAVING SUM(received_raw) - SUM(sent_raw) > 0
)
SELECT
    SUM(balance_raw) / POWER(10, 18) AS circulating_supply_bnb
FROM balances;