WITH
-- total BNB received per non-zero address
received AS (
    SELECT
        "to_address"                             AS "holder",
        SUM(TRY_TO_DECIMAL("value"))             AS "received_raw"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE  "token_address" = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
      AND  "to_address"    NOT ILIKE '0x000%'     -- exclude zero address
    GROUP  BY "to_address"
),
-- total BNB sent per non-zero address
sent AS (
    SELECT
        "from_address"                           AS "holder",
        SUM(TRY_TO_DECIMAL("value"))             AS "sent_raw"
    FROM   ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE  "token_address" = '0xb8c77482e45f1f44de1745f52c74426c631bdd52'
      AND  "from_address"  NOT ILIKE '0x000%'     -- exclude zero address
    GROUP  BY "from_address"
),
-- net balance for each holder
balances AS (
    SELECT
        COALESCE(r."holder", s."holder")                         AS "holder",
        COALESCE(r."received_raw", 0) - COALESCE(s."sent_raw",0) AS "balance_raw"
    FROM   received r
    FULL OUTER JOIN sent s
           ON r."holder" = s."holder"
)
-- circulating supply = sum of all positive balances, scaled down from 10^18
SELECT
    SUM("balance_raw") / 1e18         AS "circulating_supply_BNB"
FROM   balances
WHERE  "balance_raw" > 0;