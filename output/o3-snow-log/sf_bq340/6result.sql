WITH token_transfers_filtered AS (
    /* Keep only transfers of the two required ERC-20 contracts                  */
    SELECT 
        LOWER("token_address")        AS token_address,
        LOWER("from_address")         AS address,
        -TRY_TO_DECIMAL("value")      AS delta            -- outgoing (negative)
    FROM   CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE  LOWER("token_address") IN (
              '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
              '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
           )

    UNION ALL
    
    SELECT 
        LOWER("token_address")        AS token_address,
        LOWER("to_address")           AS address,
        TRY_TO_DECIMAL("value")       AS delta            -- incoming (positive)
    FROM   CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE  LOWER("token_address") IN (
              '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
              '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
           )
),
balances AS (
    /* Net balance change = current balance − previous (0)                      */
    SELECT
        address,
        SUM(delta)               AS current_balance,
        ABS(SUM(delta))          AS abs_difference
    FROM   token_transfers_filtered
    WHERE  address <> '0x0000000000000000000000000000000000000000'
    GROUP  BY address
)
SELECT
    address                       AS "ETH_ADDRESS",
    abs_difference                AS "ABS_DIFF"
FROM   balances
ORDER  BY abs_difference DESC NULLS LAST
LIMIT  6;