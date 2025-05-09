WITH relevant_transfers AS (
    /* bring every transfer of the two contracts
       add +value when the address receives, -value when the address sends */
    SELECT
        "token_address",
        "to_address"      AS "address",
        TO_NUMBER("value")        AS "amount_signed"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
          )

    UNION ALL

    SELECT
        "token_address",
        "from_address"    AS "address",
        -TO_NUMBER("value")       AS "amount_signed"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
          )
),

/* net balance per address & token */
balances AS (
    SELECT
        "address",
        "token_address",
        SUM("amount_signed") AS "balance"
    FROM relevant_transfers
    GROUP BY
        "address",
        "token_address"
),

/* pivot the two balances to one row per address */
pivoted AS (
    SELECT
        "address",
        COALESCE( MAX( CASE
                         WHEN "token_address" = '0x0d8775f648430679a709e98d2b0cb6250d2887ef0'
                         THEN "balance" END ), 0) AS "previous_balance",
        COALESCE( MAX( CASE
                         WHEN "token_address" = '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
                         THEN "balance" END ), 0) AS "current_balance"
    FROM balances
    GROUP BY "address"
),

/* absolute difference between the two token balances */
diffs AS (
    SELECT
        "address",
        "previous_balance",
        "current_balance",
        ABS( "current_balance" - "previous_balance" ) AS "abs_difference"
    FROM pivoted
    WHERE LOWER("address") <> '0x0000000000000000000000000000000000000000'
)

SELECT
    "address",
    "previous_balance",
    "current_balance",
    "abs_difference"
FROM diffs
ORDER BY "abs_difference" DESC NULLS LAST
LIMIT 6;