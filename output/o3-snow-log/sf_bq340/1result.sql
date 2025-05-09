WITH transfers AS (
    /* collect all transfers for the two specified tokens                     */
    SELECT 
        LOWER("from_address") AS address,
        TO_DECIMAL("value")   AS amount
    FROM   CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE  LOWER("token_address") IN (
           '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
           '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')
      AND  LOWER("from_address") <> '0x0000000000000000000000000000000000000000'
    
    UNION ALL
    
    SELECT 
        LOWER("to_address")   AS address,
        TO_DECIMAL("value")   AS amount
    FROM   CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE  LOWER("token_address") IN (
           '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
           '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')
      AND  LOWER("to_address")  <> '0x0000000000000000000000000000000000000000'
),
addr_max AS (
    /* maximum single‐transaction balance change per address                  */
    SELECT
        address,
        MAX(amount) AS abs_balance_diff
    FROM   transfers
    GROUP  BY address
)
SELECT
    address,
    abs_balance_diff
FROM   addr_max
ORDER  BY abs_balance_diff DESC NULLS LAST
LIMIT  6;