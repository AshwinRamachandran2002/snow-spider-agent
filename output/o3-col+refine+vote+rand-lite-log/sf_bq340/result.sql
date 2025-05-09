WITH deltas AS (
    /* outgoing transfers: negative delta */
    SELECT
        "from_address"     AS "addr",
        -("value"::NUMBER) AS "delta"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
          )

    UNION ALL

    /* incoming transfers: positive delta */
    SELECT
        "to_address"       AS "addr",
        ("value"::NUMBER)  AS "delta"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
          )
),

abs_changes AS (
    SELECT
        "addr"                                           AS "ethereum_address",
        ABS(SUM("delta"))                                AS "abs_balance_difference"
    FROM deltas
    WHERE "addr" <> '0x0000000000000000000000000000000000000000'
    GROUP BY "addr"
)

SELECT
    "ethereum_address" AS "address",
    "abs_balance_difference"
FROM abs_changes
ORDER BY "abs_balance_difference" DESC NULLS LAST
LIMIT 6;