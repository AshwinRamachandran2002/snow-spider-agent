WITH signed_transfers AS (
    /* incoming amounts (positive) */
    SELECT  LOWER("token_address")                       AS "token_addr",
            "block_number",
            "to_address"                                 AS "address",
            TO_DECIMAL("value")                          AS "amt"
    FROM    CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE   LOWER("token_address") IN (
              '0x0d8775f648430679a709e98d2b0cb6250d2887ef',
              '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
            )

    UNION ALL

    /* outgoing amounts (negative) */
    SELECT  LOWER("token_address")                       AS "token_addr",
            "block_number",
            "from_address"                               AS "address",
            -TO_DECIMAL("value")                         AS "amt"
    FROM    CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE   LOWER("token_address") IN (
              '0x0d8775f648430679a709e98d2b0cb6250d2887ef',
              '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
            )
),
balances AS (
    /* running balance per address & token */
    SELECT  "address",
            "token_addr",
            "block_number",
            SUM("amt") 
              OVER (PARTITION BY "address","token_addr" 
                    ORDER BY "block_number")            AS "bal"
    FROM    signed_transfers
),
latest_vs_prev AS (
    /* current vs previous balance snapshots */
    SELECT  "address",
            "token_addr",
            "bal",
            LAG("bal") 
              OVER (PARTITION BY "address","token_addr" 
                    ORDER BY "block_number" DESC)       AS "prev_bal"
    FROM    balances
)
SELECT  "address",
        SUM(ABS("bal" - "prev_bal"))                    AS "total_abs_diff"
FROM    latest_vs_prev
WHERE   "prev_bal" IS NOT NULL
  AND   "address" <> '0x0000000000000000000000000000000000000000'
GROUP BY "address"
ORDER BY "total_abs_diff" DESC NULLS LAST, "address"
LIMIT 6;