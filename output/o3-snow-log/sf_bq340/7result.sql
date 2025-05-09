WITH token_movements AS (
    /* one row per (address , transfer) showing the signed value change */
    SELECT  
        "block_number",
        "log_index",
        "from_address"                          AS address,
        - TO_NUMBER("value")                    AS delta
    FROM   CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE  "token_address" IN ( '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
                                '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')

    UNION ALL

    SELECT  
        "block_number",
        "log_index",
        "to_address"                            AS address,
        TO_NUMBER("value")                      AS delta
    FROM   CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE  "token_address" IN ( '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
                                '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')
), latest_change AS (
    /* keep only the most-recent movement per address                     */
    SELECT
        address,
        delta,
        ROW_NUMBER() OVER (PARTITION BY address
                           ORDER BY "block_number" DESC, "log_index" DESC) AS rn
    FROM   token_movements
    WHERE  address <> '0x0000000000000000000000000000000000000000'
)
SELECT  address,
        ABS(delta) AS absolute_difference
FROM    latest_change
WHERE   rn = 1                         -- most-recent movement
ORDER BY absolute_difference DESC NULLS LAST
LIMIT   6;