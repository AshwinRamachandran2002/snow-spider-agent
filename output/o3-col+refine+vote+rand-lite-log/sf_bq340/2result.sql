-- six addresses with the largest absolute net balance change
WITH all_transfers AS (
    /*  incoming amounts are positive, outgoing amounts are negative  */
    SELECT  "to_address"   AS addr,
            TO_DECIMAL("value")          AS amount
    FROM    CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE   "token_address" IN (
              '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
              '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
            )

    UNION ALL

    SELECT  "from_address" AS addr,
            -TO_DECIMAL("value")         AS amount
    FROM    CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE   "token_address" IN (
              '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
              '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
            )
)
SELECT  addr                                           AS address,
        SUM(amount)                                    AS net_change
FROM    all_transfers
WHERE   addr <> '0x0000000000000000000000000000000000000000'
GROUP BY addr
ORDER BY ABS(net_change) DESC NULLS LAST
LIMIT 6;