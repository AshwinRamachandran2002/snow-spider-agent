WITH token_moves AS (
    /* inflows add value */
    SELECT 
        LOWER("to_address")   AS "eth_address",
        TO_DECIMAL("value")   AS "delta"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") IN (
        '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
        '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
    )
    
    UNION ALL
    
    /* outflows subtract value */
    SELECT 
        LOWER("from_address") AS "eth_address",
        -TO_DECIMAL("value")  AS "delta"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE LOWER("token_address") IN (
        '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
        '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
    )
)

SELECT
    "eth_address"                                     AS "ETH_ADDRESS",
    ABS(SUM("delta"))                                 AS "ABS_BALANCE_DIFF"
FROM token_moves
WHERE "eth_address" <> '0x0000000000000000000000000000000000000000'
GROUP BY "eth_address"
ORDER BY "ABS_BALANCE_DIFF" DESC NULLS LAST,
         "ETH_ADDRESS"
LIMIT 6;