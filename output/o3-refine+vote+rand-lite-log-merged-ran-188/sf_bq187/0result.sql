WITH "BNB_TOKEN" AS (             -- all ERC‑20 contracts whose symbol is exactly ‘BNB’
    SELECT  "address" AS token_address
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKENS
    WHERE   UPPER("symbol") = 'BNB'
),

/* only BNB transfers that do NOT involve the zero address
   (so mints/burns are ignored as requested) */
"BNB_TRANSFERS" AS (
    SELECT  *
    FROM    ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS
    WHERE   "token_address" IN (SELECT token_address FROM "BNB_TOKEN")
      AND   LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
      AND   LOWER("to_address")   <> '0x0000000000000000000000000000000000000000'
),

/* convert transfers into signed balance changes                */
"BALANCE_CHANGES" AS (
    -- positive change (tokens received)
    SELECT  "to_address"   AS address,
            TRY_CAST("value" AS NUMBER)                 AS delta
    FROM    "BNB_TRANSFERS"
    UNION ALL
    -- negative change (tokens sent)
    SELECT  "from_address" AS address,
            -TRY_CAST("value" AS NUMBER)                AS delta
    FROM    "BNB_TRANSFERS"
),

/* net balance per (non‑zero) address, clipped at zero so nobody can be “negative” */
"BALANCES" AS (
    SELECT  address,
            GREATEST(SUM(delta), 0)     AS balance_wei       -- still in Wei
    FROM    "BALANCE_CHANGES"
    GROUP BY address
)

-- circulating supply in whole tokens (divide by 10¹⁸)
SELECT  SUM(balance_wei) / 1e18        AS "BNB_CIRCULATING_SUPPLY"
FROM    "BALANCES";