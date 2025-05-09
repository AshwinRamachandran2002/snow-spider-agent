WITH transfers AS (
    /* + amount to recipient , – amount from sender */
    SELECT
        "token_address",
        "block_number",
        "to_address"                AS "address",
        TRY_TO_NUMBER("value")      AS "delta"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',   -- BAT  (as given)
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'     -- second token
         )

    UNION ALL

    SELECT
        "token_address",
        "block_number",
        "from_address"              AS "address",
        -TRY_TO_NUMBER("value")     AS "delta"
    FROM CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE "token_address" IN (
            '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
            '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
         )
),
balances AS (
    /* running balance per (token,address) over time */
    SELECT
        "token_address",
        "address",
        "block_number",
        SUM("delta") OVER (
              PARTITION BY "token_address", "address"
              ORDER BY     "block_number"
        )                           AS "running_balance"
    FROM transfers
),
step_diffs AS (
    /* absolute change from previous block for each (token,address) */
    SELECT
        "address",
        ABS( "running_balance"
           - LAG("running_balance") OVER (
                 PARTITION BY "token_address", "address"
                 ORDER BY     "block_number"
             )
        )                           AS "abs_step_diff"
    FROM balances
    WHERE "address" <> '0x0000000000000000000000000000000000000000'
          -- zero-address excluded
          AND "running_balance" IS NOT NULL
)
SELECT  "address"
FROM    step_diffs
WHERE   "abs_step_diff" IS NOT NULL       -- skip first rows with no previous balance
GROUP BY "address"
ORDER BY MAX("abs_step_diff") DESC NULLS LAST
LIMIT 6;