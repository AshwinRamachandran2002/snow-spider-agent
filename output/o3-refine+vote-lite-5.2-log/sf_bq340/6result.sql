SELECT 
    addr      AS "ethereum_address",
    diff      AS "absolute_balance_difference"
FROM (
    SELECT 
        addr,
        ABS(SUM(amount)) AS diff
    FROM (
        /* incoming transfers add to balance */
        SELECT 
            LOWER("to_address")   AS addr,
            TO_DECIMAL("value")   AS amount
        FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
        WHERE LOWER("token_address") IN (
                '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
                '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
              )
          AND LOWER("to_address") <> '0x0000000000000000000000000000000000000000'
        
        UNION ALL
        
        /* outgoing transfers subtract from balance */
        SELECT 
            LOWER("from_address") AS addr,
            -TO_DECIMAL("value")  AS amount
        FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
        WHERE LOWER("token_address") IN (
                '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
                '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
              )
          AND LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
    ) AS movements
    GROUP BY addr
) AS balances
ORDER BY diff DESC NULLS LAST, addr
LIMIT 6;