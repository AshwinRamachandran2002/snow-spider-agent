WITH token_moves AS (
    /* inbound transfers (positive) */
    SELECT
        LOWER("to_address")      AS "address",
        TRY_TO_DECIMAL("value")  AS "amount_signed"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE LOWER("token_address") IN (
          '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
          '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
    )

    UNION ALL

    /* outbound transfers (negative) */
    SELECT
        LOWER("from_address")    AS "address",
        -TRY_TO_DECIMAL("value") AS "amount_signed"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE LOWER("token_address") IN (
          '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
          '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
    )
)

SELECT
    "address"                              AS "ethereum_address",
    ABS(SUM("amount_signed"))              AS "absolute_balance_difference"
FROM token_moves
WHERE "address" <> '0x0000000000000000000000000000000000000000'
GROUP BY "address"
ORDER BY "absolute_balance_difference" DESC NULLS LAST
LIMIT 6;