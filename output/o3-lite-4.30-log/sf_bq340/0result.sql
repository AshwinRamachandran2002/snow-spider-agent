WITH
/* -------------------------------------------------------------------- */
/* 1. ERC‑20 contracts under review                                     */
tokens AS (
    SELECT DISTINCT column1 AS token_addr
    FROM ( VALUES
            ('0x0d8775f648430679a709e98d2b0cb6250d2887ef'),   -- BAT  (valid)
            ('0x0d8775f648430679a709e98d2b0cb6250d2887ef0'),  -- typo in prompt – keep to be safe
            ('0x1e15c05cbad367f044cbfbafda3d9a1510db5513')    -- 1INCH‑v1
         )
),

/* -------------------------------------------------------------------- */
/* 2. expand transfers into signed amounts (+in / –out)                 */
all_transfers AS (
    SELECT
        "token_address",
        "block_number",
        "to_address"                   AS wallet,
        TO_DECIMAL("value")            AS amount
    FROM  CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" IN (SELECT token_addr FROM tokens)

    UNION ALL

    SELECT
        "token_address",
        "block_number",
        "from_address"                 AS wallet,
        - TO_DECIMAL("value")          AS amount
    FROM  CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" IN (SELECT token_addr FROM tokens)
),

/* -------------------------------------------------------------------- */
/* 3. first & last block numbers available per token                    */
first_last AS (
    SELECT
        token_addr,
        MIN("block_number") AS first_block,
        MAX("block_number") AS last_block
    FROM   tokens
    JOIN   all_transfers  ON token_addr = "token_address"
    GROUP  BY token_addr
),

/* -------------------------------------------------------------------- */
/* 4. balances aggregated up to FIRST and up to LAST snapshot           */
balances AS (
    /* -------- first snapshot -------- */
    SELECT
        fl.token_addr,
        'FIRST'             AS tag,
        at.wallet,
        SUM(at.amount)      AS balance
    FROM first_last fl
    JOIN all_transfers at
         ON at."token_address" = fl.token_addr
        AND at."block_number"  <= fl.first_block
    GROUP BY fl.token_addr, at.wallet

    UNION ALL

    /* -------- last snapshot --------- */
    SELECT
        fl.token_addr,
        'LAST'              AS tag,
        at.wallet,
        SUM(at.amount)      AS balance
    FROM first_last fl
    JOIN all_transfers at
         ON at."token_address" = fl.token_addr
        AND at."block_number"  <= fl.last_block
    GROUP BY fl.token_addr, at.wallet
),

/* -------------------------------------------------------------------- */
/* 5. absolute balance change per (token, wallet)                       */
per_token AS (
    SELECT
        token_addr,
        wallet,
        ABS(
              COALESCE(MAX(CASE WHEN tag = 'LAST'  THEN balance END), 0)
            - COALESCE(MAX(CASE WHEN tag = 'FIRST' THEN balance END), 0)
        ) AS abs_delta
    FROM balances
    GROUP BY token_addr, wallet
    HAVING wallet IS NOT NULL
),

/* -------------------------------------------------------------------- */
/* 6. total change across the two tokens & top‑6 addresses              */
ranked AS (
    SELECT
        wallet                         AS ethereum_address,
        SUM(abs_delta)                 AS absolute_balance_difference
    FROM   per_token
    WHERE  LOWER(wallet) <> '0x0000000000000000000000000000000000000000'
    GROUP  BY wallet
)

SELECT
    ethereum_address,
    absolute_balance_difference
FROM   ranked
ORDER  BY absolute_balance_difference DESC NULLS LAST, ethereum_address
LIMIT  6;