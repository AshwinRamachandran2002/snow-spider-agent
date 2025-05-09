WITH token_transfers AS (
    SELECT
        LOWER("from_address")                         AS "address",
        -TO_NUMBER("value")                           AS "change"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',   -- BAT
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'    -- ELF
          )
      AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'

    UNION ALL

    SELECT
        LOWER("to_address")                           AS "address",
        TO_NUMBER("value")                            AS "change"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
          )
      AND LOWER("to_address") <> '0x0000000000000000000000000000000000000000'
),
balance_diffs AS (
    SELECT
        "address",
        SUM("change") AS "net_change"
    FROM token_transfers
    GROUP BY "address"
)
SELECT
    "address"
FROM balance_diffs
ORDER BY ABS("net_change") DESC NULLS LAST
FETCH FIRST 6 ROWS;