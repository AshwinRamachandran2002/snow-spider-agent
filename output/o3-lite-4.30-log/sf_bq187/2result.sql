WITH bnb_token AS (   -- Binance‑Peg BNB contract on Ethereum
    SELECT '0xb8c77482e45f1f44de1745f52c74426c631bdd52'::TEXT AS address
),
recv AS (             -- total BNB received by every non‑zero address
    SELECT "to_address"                         AS addr,
           SUM(TRY_TO_DECIMAL("value"))         AS rec_raw
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS"
    WHERE  "token_address" = (SELECT address FROM bnb_token)
      AND  "to_address"   <> '0x0000000000000000000000000000000000000000'
    GROUP  BY "to_address"
),
sent AS (             -- total BNB sent by every non‑zero address
    SELECT "from_address"                       AS addr,
           SUM(TRY_TO_DECIMAL("value"))         AS sen_raw
    FROM   "ETHEREUM_BLOCKCHAIN"."ETHEREUM_BLOCKCHAIN"."TOKEN_TRANSFERS"
    WHERE  "token_address" = (SELECT address FROM bnb_token)
      AND  "from_address" <> '0x0000000000000000000000000000000000000000'
    GROUP  BY "from_address"
),
balances AS (         -- net balance per address
    SELECT COALESCE(r.addr, s.addr)             AS addr,
           COALESCE(r.rec_raw, 0)
           - COALESCE(s.sen_raw, 0)             AS bal_raw
    FROM   recv r
    FULL  JOIN sent s ON r.addr = s.addr
)
SELECT
    'BNB'                                        AS token,
    ROUND(SUM(bal_raw) / POW(10, 18), 4)         AS circulating_supply
FROM   balances
WHERE  bal_raw <> 0;