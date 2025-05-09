WITH transfers AS (   -- signed token movements for the two target tokens
    SELECT
        "token_address",
        "to_address"                             AS addr,
        TRY_TO_NUMBER("value")                  AS delta,
        "block_number"
    FROM  CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
          )

    UNION ALL

    SELECT
        "token_address",
        "from_address"                           AS addr,
        -TRY_TO_NUMBER("value")                 AS delta,
        "block_number"
    FROM  CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
          )
),

running_bal AS (     -- cumulative balances per address & token
    SELECT
        "token_address",
        addr,
        "block_number",
        SUM(delta) OVER (PARTITION BY "token_address", addr
                         ORDER BY "block_number"
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS bal,
        ROW_NUMBER()   OVER (PARTITION BY "token_address", addr
                             ORDER BY "block_number" DESC)                 AS rn
    FROM transfers
    WHERE addr <> '0x0000000000000000000000000000000000000000'
),

prev_curr AS (       -- pick current and previous balances
    SELECT
        "token_address",
        addr,
        MAX(CASE WHEN rn = 1 THEN bal END) AS current_bal,
        MAX(CASE WHEN rn = 2 THEN bal END) AS prev_bal
    FROM running_bal
    GROUP BY "token_address", addr
    HAVING prev_bal IS NOT NULL            -- need both balances to compute a change
),

diffs AS (           -- absolute balance changes
    SELECT
        addr,
        ABS(current_bal - prev_bal) AS abs_diff
    FROM prev_curr
)

SELECT
    addr                          AS "ethereum_address",
    MAX(abs_diff)                 AS "abs_diff"   -- largest change across the two tokens
FROM diffs
GROUP BY addr
ORDER BY "abs_diff" DESC NULLS LAST
LIMIT 6;