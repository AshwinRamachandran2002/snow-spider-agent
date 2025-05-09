WITH token_tx AS (
    SELECT
        LOWER("token_address")            AS token,
        LOWER("from_address")             AS from_addr,
        LOWER("to_address")               AS to_addr,
        TRY_TO_DECIMAL("value")           AS val
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") IN (
        '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',   -- BAT
        '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'    -- second token
    )
),                                                -- outgoing  (‑)
deltas AS (
    SELECT to_addr   AS addr,  val        AS delta FROM token_tx
    UNION ALL
    SELECT from_addr AS addr, -val        AS delta FROM token_tx
),                                                -- balance change per address
balances AS (
    SELECT
        addr,
        SUM(delta)           AS balance_change
    FROM deltas
    WHERE addr <> '0x0000000000000000000000000000000000000000'
    GROUP BY addr
)
SELECT
    addr        AS "ETH_ADDRESS",
    balance_change      AS "BALANCE_DIFFERENCE"
FROM balances
ORDER BY ABS(balance_change) DESC NULLS LAST, addr
FETCH FIRST 6 ROWS ONLY;