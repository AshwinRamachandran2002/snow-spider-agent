WITH token_moves AS (

    /* all transfers of the first token */
    SELECT  LOWER("to_address")   AS "address",
            TO_DECIMAL("value")   AS "amt"
    FROM    CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE   "token_address" = '0x0d8775f648430679a709e98d2b0cb6250d2887ef0'

    UNION ALL
    SELECT  LOWER("from_address") AS "address",
           -TO_DECIMAL("value")   AS "amt"
    FROM    CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE   "token_address" = '0x0d8775f648430679a709e98d2b0cb6250d2887ef0'


    /* all transfers of the second token */
    UNION ALL
    SELECT  LOWER("to_address")   AS "address",
            TO_DECIMAL("value")   AS "amt"
    FROM    CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE   "token_address" = '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'

    UNION ALL
    SELECT  LOWER("from_address") AS "address",
           -TO_DECIMAL("value")   AS "amt"
    FROM    CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE   "token_address" = '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
)

SELECT  "address",
        SUM("amt")                         AS "net_change",
        ABS(SUM("amt"))                    AS "abs_change"
FROM    token_moves
WHERE   "address" <> '0x0000000000000000000000000000000000000000'
GROUP BY "address"
ORDER BY "abs_change" DESC NULLS LAST
LIMIT 6;