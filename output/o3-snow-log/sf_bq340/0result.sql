WITH token_transfers_filtered AS (

    /* outgoing transfers (subtract value) */
    SELECT 
        LOWER("from_address")                                             AS "address",
        -TRY_CAST("value" AS NUMBER(38,0))                                AS "amount"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") IN (
          '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
          '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
    )

    UNION ALL

    /* incoming transfers (add value) */
    SELECT 
        LOWER("to_address")                                               AS "address",
        TRY_CAST("value" AS NUMBER(38,0))                                 AS "amount"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") IN (
          '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
          '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
    )

)

SELECT 
    "address"                                    AS "ethereum_address",
    SUM("amount")                                AS "net_balance_change",
    ABS(SUM("amount"))                           AS "absolute_change"
FROM token_transfers_filtered
WHERE "address" <> '0x0000000000000000000000000000000000000000'
GROUP BY "address"
ORDER BY "absolute_change" DESC NULLS LAST
LIMIT 6;